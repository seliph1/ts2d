local state = require 'lib/state'
local enet = require 'enet' -- Network
-- local marshal = require 'marshal' -- Serialization
-- local serpent = require 'lib/serpent'
local bitser = require 'lib/bitser'

local encode = bitser.dumps
local decode = bitser.loads

local MAX_MAX_CLIENTS = 64

local client = {}
do
    client.enabled = false
    client.sessionToken = nil
    client.sendRate = 35
    client.numChannels = 1

    client.connected = false
    client.id = nil
    client.backgrounded = false

    local share = {}
    client.share = share
    local home = state.new()
    home:__autoSync(true)
    client.home = home

    local host
    local peer

    local useCompression = true
    function client.disableCompression()
        useCompression = false
    end

    function client.start(address)
		local address = address or '127.0.0.1:36963'
        --host = enet.host_create(nil, 1, client.numChannels)
        host = enet.host_create()
        if useCompression then
            host:compress_with_range_coder()
        end
		print("client peer started ("..tostring(host)..")")
		print("attempting connection to: "..address)
		host:connect(address, client.numChannels)
    end

    function client.sendExt(channel, flag, ...)
		if peer then
			peer:send(encode({
				message = { nArgs = select('#', ...), ... },
			}), channel, flag)
		end
    end

    function client.send(...)
        client.sendExt(nil, nil, ...)
    end

    function client.kick()
        assert(peer, 'client is not connected'):disconnect()
        host:flush()
    end

    function client.getPing()
		if peer then
			return peer:round_trip_time()
		else
			return 0
		end
    end

    function client.getENetHost()
        return host
    end

    function client.getENetPeer()
        return peer
    end

    function client.preupdate(dt)
        -- Process network events
        if host then
            while true do
                if not host then break end
                local event = host:service(0)
                if not event then break end
                -- Server connected?
                if event.type == 'connect' then
                    -- Ignore this, wait till we receive id (see below)
					print("connected")
                end

                -- Server disconnected?
                if event.type == 'disconnect' then
                    if client.disconnect then
                        client.disconnect()
                    end
                    client.connected = false
                    client.id = nil
                    for k in pairs(share) do
                        share[k] = nil
                    end
                    for k in pairs(home) do
                        home[k] = nil
                    end
                    host = nil
                    peer = nil
					print("disconnected")
                end

                -- Received a request?
                if event.type == 'receive' then
                    local request = decode(event.data)

                    -- Message?
                    if request and request.message then
                        if client.receive then
                            client.receive(unpack(request.message, 1, request.message.nArgs))
                        end
                    end

                    -- Diff / exact? (do this first so we have it in `.connect` below)
                    if request and request.diff then
                        if client.changing then
                            client.changing(request.diff)
                        end
                        assert(state.apply(share, request.diff) == share)
                        if client.changed then
                            client.changed(request.diff)
                        end
                    end
                    if request and request.exact then -- `state.apply` may return a new value
                        if client.changing then
                            client.changing(request.exact)
                        end
                        local new = state.apply(share, request.exact)
                        for k, v in pairs(new) do
                            share[k] = v
                        end
                        for k in pairs(share) do
                            if not new[k] then
                                share[k] = nil
                            end
                        end
                        if client.changed then
                            client.changed(request.exact)
                        end
                    end

                    -- Id?
                    if request and request.id then
                        peer = event.peer
                        client.connected = true
                        client.id = request.id
                        if client.connect then
                            client.connect()
                        end
						print(string.format("received id %s", client.id))

                        -- Send sessionToken now that we have an id
                        peer:send(encode({
                            sessionToken = client.sessionToken,
                            exact = home:__diff(0, true)
                        }))
                    end

                    -- Full?
                    if request and request.full then
                        if client.full then
                            client.full()
                        end
                    end
                end
            end
        end
    end

    local timeSinceLastUpdate = 0

    function client.postupdate(dt)
        timeSinceLastUpdate = timeSinceLastUpdate + dt
        if timeSinceLastUpdate < 1 / client.sendRate then
            return
        end
        timeSinceLastUpdate = 0

        -- Send state updates to server
        if peer then
            local diff = home:__diff(0)
            if diff ~= nil then -- `nil` if nothing changed
                peer:send(encode({ diff = diff }))
            end
        end
        home:__flush() -- Make sure to reset diff state after sending!

        if host then
            host:flush() -- Tell ENet to send outgoing messages
        end
    end
end

return {
    client = client,
    DIFF_NIL = state.DIFF_NIL,
}
