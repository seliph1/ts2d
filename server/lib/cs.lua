local state = require 'lib/state'


local enet = require 'enet' -- Network
-- local marshal = require 'marshal' -- Serialization
local serpent = require 'lib/serpent'
local bitser = require 'lib/bitser'


local encode = bitser.dumps
local decode = bitser.loads


local MAX_MAX_CLIENTS = 64


local server = {}
do
    server.enabled = false
    server.maxClients = MAX_MAX_CLIENTS
    server.isAcceptingClients = true
    server.sendRate = 35
    server.numChannels = 1
	server.log_level = 1

    server.started = false
    server.backgrounded = false

    local share = state.new()
    share:__autoSync(true)
    server.share = share
    local homes = {}
    server.homes = homes

    local host
    local peerToId = {}
    local idToPeer = {}
    local idToSessionToken = {}
    local nextId = 1
    local numClients = 0

    --local useCompression = true
    local useCompression = false
    function server.disableCompression()
        useCompression = false
    end


	local log_storage = {}
	function server.log(level, ...)
		local args = {...}
		local separator = " | "
		local entry = string.format( "%s%s%s", os.date("%X",os.time()), separator,  table.concat(args, separator))
		table.insert(log_storage, entry)
		if level >= server.log_level then
			print(entry)
		end	
	end


    function server.start(address, port)
		local address = address or "localhost"
		local port = port or "36963"
		
        --host = enet.host_create(address .. ":" .. tostring(port), MAX_MAX_CLIENTS, server.numChannels)
        host = enet.host_create("127.0.0.1:36963", MAX_MAX_CLIENTS, server.numChannels)
        if host == nil then
			server.log(7, "server", "couldn't start server -- is port in use?")
            return
        end
        if useCompression then
            host:compress_with_range_coder()
        end
        server.started = true
		server.log(7, "server", "enet server started")
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

    function server.getENetHost()
        return host
    end

    function server.getENetPeer(id)
        return idToPeer[id]
    end

    function server.preupdate()
        -- Process network events
        if host then
            while true do
                local event = host:service(0)
                if not event then break end

                -- Someone connected?
                if event.type == 'connect' then
					server.log(7, "server", "connection attempt from "..tostring(event.peer))
                    if numClients < server.maxClients then
                        local id = nextId
                        nextId = nextId + 1
                        peerToId[event.peer] = id
                        idToPeer[id] = event.peer
                        homes[id] = {}
                        numClients = numClients + 1
                        if server.connect then
                            server.connect(id)
                        end
                        event.peer:send(encode({
                            id = id,
                            exact = share:__diff(id, true),
                        }))
                    else
                        event.peer:send(encode({ full = true }))
                        event.peer:disconnect_later()
						server.log(7, "server", tostring(event.peer).." connection refused: server is full")
                    end
                end

                -- Someone disconnected?
                if event.type == 'disconnect' then
                    local id = peerToId[event.peer]
                    if id then
                        if server.disconnect then
                            server.disconnect(id)
                        end
                        homes[id] = nil
                        idToPeer[id] = nil
                        peerToId[event.peer] = nil
                        idToSessionToken[id] = nil
                        numClients = numClients - 1
						
						server.log(7, "server", tostring(event.peer).." disconnected")
                    end
                end

                -- Received a request?
                if event.type == 'receive' then
                    local id = peerToId[event.peer]
                    if id then
                        local request = decode(event.data)

                        -- Session token?
                        if request.sessionToken then
                            idToSessionToken[id] = request.sessionToken
                        end

                        -- Message?
                        if request.message and server.receive then
                            server.receive(id, unpack(request.message, 1, request.message.nArgs))
                        end

                        -- Diff / exact?
                        if request.diff then
                            if server.changing then
                                server.changing(id, request.diff)
                            end
                            assert(state.apply(homes[id], request.diff) == homes[id])
                            if server.changed then
                                server.changed(id, request.diff)
                            end
                        end
                        if request.exact then -- `state.apply` may return a new value
                            if server.changing then
                                server.changing(id, request.exact)
                            end
                            local home = homes[id]
                            local new = state.apply(home, request.exact)
                            for k, v in pairs(new) do
                                home[k] = v
                            end
                            for k in pairs(home) do
                                if not new[k] then
                                    home[k] = nil
                                end
                            end
                            if server.changed then
                                server.changed(id, request.exact)
                            end
                        end
                    end
                end
            end
        end
    end

    local timeSinceLastUpdate = 0

    function server.postupdate(dt)
        timeSinceLastUpdate = timeSinceLastUpdate + dt
        if timeSinceLastUpdate < 1 / server.sendRate then
            return
        end
        timeSinceLastUpdate = 0

        -- Send state updates to everyone
        for peer, id in pairs(peerToId) do
            local diff = share:__diff(id)
            if diff ~= nil then -- `nil` if nothing changed
                peer:send(encode({ diff = diff }))
            end
        end
        share:__flush() -- Make sure to reset diff state after sending!

        if host then
            host:flush() -- Tell ENet to send outgoing messages
        end

    end
end

return {
    server = server,
    client = client,
    DIFF_NIL = state.DIFF_NIL,
}
