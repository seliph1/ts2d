local state               = require 'lib.state'
local enet                = require 'enet' -- Network
local serpent             = require 'lib.serpent'
local cbor                = require 'lib.cbor'

local encode              = cbor.encode
local decode              = cbor.decode

local MAX_CLIENTS         = 64
local SEND_RATE           = 35
local server              = {}

server.enabled            = false
server.maxClients         = MAX_CLIENTS
server.sendRate           = SEND_RATE
server.isAcceptingClients = true
server.numChannels        = 3
server.log_level          = 1

server.started            = false
server.backgrounded       = false
server.version            = "*"
server.clock              = 0
server.stateDumpOpts      = { comment = false }
server.dt                 = 0

-- state object
local share               = state.new()
share:__autoSync(true)
server.share = share

-- home data holding
local homes = {}
server.homes = homes

-- Peer data holding
local host
local peerToId = {}
local idToPeer = {}
local idToSessionToken = {}
local idToSessionIdentity = {}
local idToSettings = {}
local nextId = 1
local numClients = 0
local useCompression = true

-- something something compression
function server.disableCompression()
	useCompression = false
end

-- log function helper
local log_storage = {}
function server.log(level, ...)
	--[[
	local args = {...}
	--local entry = string.format( "%s%s%s", os.date("%X",os.time()), separator,  table.concat(args, separator))
	local entry = string.format( "%s %s", os.date("%X", os.time()),  table.concat(args, "", 2))
	table.insert(log_storage, entry)
	if level >= server.log_level then
		print(entry)
	end	
	--]]
	--[[
	local args = {...}
	for index, value in ipairs(args) do
		entry = entry .. tostring(value)
		if index < #args then
			--entry == entry .. separator
		end	
	end
	--]]
	local separator = " "
	local str = {
		string.format("%s", os.date("%X", os.time()))
	}

	for i = 2, select("#", ...) do
		local v = select(i, ...)
		v = tostring(v)
		table.insert(str, v)
	end

	if level >= server.log_level then
		print(table.concat(str, separator))
	end
end

function server.start(address, port)
	address = address or "127.0.0.1"
	port = port or "36963"

	server.log(7, "server", string.format("initializing UDP socket with %s:%s", address, port))
	host = enet.host_create(string.format("%s:%s", address, port), server.maxClients, server.numChannels)
	if host == nil then
		server.log(7, "server", string.format("couldn't start server -- is port %s in use?", port))
		return
	end
	if useCompression then
		host:compress_with_range_coder()
	end
	server.started = true
	server.log(7, "server", "enet server started")
end

--- Para o servidor e libera o socket UDP (a porta), permitindo re-hospedar.
--- Seguro chamar mais de uma vez. Usado pelo listen server (thread) e pelo --server.
function server.shutdown()
	if host then
		host:flush()
		host:destroy()
		host = nil
	end
	server.started = false
	server.log(7, "server", "enet server stopped")
end

function server.clientExists(id)
	return idToPeer[id] ~= nil
end

function server.sendExt(id, channel, flag, ...)
	local data = encode({ message = { nArgs = select('#', ...), ... } })
	if id == 'all' then
		host:broadcast(data, channel, flag)
	else
		if server.clientExists(id) then
			idToPeer[id]:send(data, channel, flag)
		else
			server.log(1, "error", 'no connected client with this `id`')
		end
	end
end

function server.broadcast(data)
	host:broadcast(encode(data))
end

function server.send(id, ...)
	server.sendExt(id, nil, nil, ...)
end

function server.kick(id)
	if server.clientExists(id) then
		idToPeer[id]:disconnect()
	else
		server.log(1, "error", 'no connected client with this `id`')
	end
end

function server.getPing(id)
	if server.clientExists(id) then
		return idToPeer[id]:round_trip_time()
	else
		server.log(1, "error", 'no connected client with this `id`')
	end
end

function server.getClientName(id)
	return idToSessionIdentity[id] or "Player"
end

function server.getENetHost()
	return host
end

function server.getENetPeer(id)
	return idToPeer[id]
end

function server.getSettings(id, setting)
	if idToSettings[id] and idToSettings[id][setting] then
		return idToSettings[id][setting]
	end
end

local timeSinceLastUpdate = 0
function server.postupdate(dt)
	if server.frame then
		server.frame(dt)
	end

	timeSinceLastUpdate = timeSinceLastUpdate + dt
	if timeSinceLastUpdate < 1 / server.sendRate then
		return
	end
	-- Call the server tick. Should correspond to send rate.
	if server.tick then
		server.dt = timeSinceLastUpdate
		server.tick(server.dt)
	end
	timeSinceLastUpdate = 0

	-- Send state updates to everyone
	for peer, id in pairs(peerToId) do
		local diff = share:__diff(id)
		if diff ~= nil then
			local gameState = {
				diff = diff,
			}
			peer:send(encode(gameState), 1)
		end
		--print(serpent.line(full, server.stateDumpOpts))
	end
	share:__flush() -- Make sure to reset diff state after sending!

	if host then
		host:flush() -- Tell ENet to send outgoing messages
	end
end

function server.preupdate(dt)
	-- Process network events
	if not host then return end

	while true do
		local event = host:service(0)
		if not event then break end

		-- Someone connected?
		if event.type == 'connect' then
			server.connect_handler(event)
		end

		-- Someone disconnected?
		if event.type == 'disconnect' then
			server.disconnect_handler(event)
		end

		-- Received a request?
		if event.type == 'receive' then
			server.request_handler(event)
		end
	end
end

function server.request_handler(event)
	local peer_id = peerToId[event.peer]
	local request = decode(event.data)
	local peer = event.peer

	if not request then return end

	-- SERVER/CLIENT AUTHENTICATION
	----------------------------------------------------------------------------
	-- Receiving name and session token from client
	if request.name then
		server.log(1, "server", "Client " .. request.name .. " joined!")

		if server.identity then
			server.identity(peer_id, request.name)
		end
		idToSessionIdentity[peer_id] = request.name
	end

	if request.sessionToken then
		idToSessionToken[peer_id] = request.sessionToken
		server.log(1, "server", "Client token: " .. request.sessionToken)
	end

	if request.version then
		-- Requesting version!
		server.log(1, "server", "Client version:  " .. request.version)

		-- Compare versions
		if request.version ~= server.version then
			-- Mismatch versions, disconnect this client
			peer:send(encode({
				warning = "Connection refused: Client version mismatch!"
			}))
			peer:disconnect_later()
			server.log(7, "server", tostring(event.peer) .. " connection refused: Client version mismatch!")
		else
			-- Agree with client version, send acknowledgment.
			peer:send(encode({
				versionAck = true
			}))
		end
	end

	if request.settings then
		idToSettings[peer_id] = idToSettings[peer_id] or {}
		for index, value in pairs(request.settings) do
			idToSettings[peer_id][index] = value
		end
	end

	if request.dataRequest then
		if server.prejoin then
			server.prejoin(peer_id)
		end

		-- Client now requested data from us
		-- Lets send it and receive the join confirmation back.
		peer:send(encode({
			exact = share:__diff(peer_id, true),
			joinAck = true,
		}))

		-- Also trigger some callbacks.
		if server.join then
			server.join(peer_id)
		end

		-- Send announcement to all connected host
		host:broadcast(encode({
			peer_joined = peer_id,
		}))
	end

	-- SERVER/CLIENT COMMS
	----------------------------------------------------------------------------
	-- Message?
	if request.message and server.receive then
		server.receive(peer_id, unpack(request.message, 1, request.message.nArgs))
	end

	-- INPUT MANAGER
	----------------------------------------------------------------------------
	if request and request.inputStream then
		--print(serpent.line(request.inputStream, server.stateDumpOpts))
		peer:send(encode({
			inputAck = request.seq
			--dt = server.dt
		}), 1, "reliable")
		-- Trigger the response for this input event (usually a player movement)
		if server.input_response then
			for k, v in pairs(request.inputStream) do
				if v == state.DIFF_NIL then
					request.inputStream[k] = nil
				end
			end
			server.input_response(peer_id, request.inputStream, request.seq)
		end
	end

	-- HOME MANAGER
	----------------------------------------------------------------------------

	if request and request.diff then
		local home = homes[peer_id]
		if server.changing then
			server.changing(peer_id, request.diff)
		end
		assert(state.apply(home, request.diff) == home)
		if server.changed then
			server.changed(peer_id, request.diff)
		end
		--print(serpent.line(request.diff, server.stateDumpOpts))
	end

	if request and request.exact then -- `state.apply` may return a new value
		local home = homes[peer_id]
		if server.changing then
			server.changing(peer_id, request.exact)
		end
		local new = state.apply(home, request.exact)
		for k, v in pairs(new) do
			home[k] = v
		end
		for k in pairs(home) do
			if not new[k] then
				home[k] = nil
			end
		end
		--print(serpent.line(request.exact, server.stateDumpOpts))
		if server.changed then
			server.changed(peer_id, request.exact)
		end
	end
end

function server.prefix_filter(t)
	for k, v in pairs(t) do
		if k:match("^_[^_]") then
			t[k] = nil
		end
		if type(v) == "table" then
			server.prefix_filter(v)
		end
	end
end

function server.disconnect_handler(event)
	local peer_id = peerToId[event.peer]
	local peer = event.peer

	if server.disconnect then
		server.disconnect(peer_id)
	end

	homes[peer_id] = nil
	idToPeer[peer_id] = nil
	peerToId[peer] = nil
	idToSessionToken[peer_id] = nil
	idToSessionIdentity[peer_id] = nil
	idToSettings[peer_id] = nil
	numClients = numClients - 1

	-- Send announcement to all connected host
	host:broadcast(encode({
		peer_disconnected = peer_id,
	}))
end

function server.connect_handler(event)
	local peer = event.peer

	server.log(7, "server", "connection attempt from " .. tostring(peer))
	if numClients < server.maxClients then
		local peer_id = #idToPeer + 1 -- Get the next free ID
		peerToId[peer] = peer_id
		idToPeer[peer_id] = peer
		homes[peer_id] = {}
		numClients = numClients + 1

		if server.connect then
			server.connect(peer_id)
		end
		-- Sends a client id to this server.
		peer:send(encode({
			id = peer_id,
		}))

		-- Send announcement to all connected host
		host:broadcast(encode({
			peer_connected = peer_id,
		}))
	else
		peer:send(encode({
			full = true,
			warning = "Connection refused: Server is full"
		}))

		peer:disconnect_later()
		server.log(7, "server", tostring(peer) .. " connection refused: server is full")
	end
end

function server.attribute(peer_id, attribute)
	local home = homes[peer_id]
	if not home then return end
	local value = home[attribute]
	if value == state.DIFF_NIL then
		return nil
	else
		return value
	end
end

server.attr = server.attribute

return {
	server = server,
}
