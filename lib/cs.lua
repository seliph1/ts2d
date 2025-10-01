local enet      = require 'enet'
local state     = require 'lib.state'
local bitser    = require 'lib.bitser'
local serpent   = require 'lib.serpent'
local List      = require 'lib.list'
local Buffer    = require 'lib.buffer'

local encode = bitser.dumps
local decode = bitser.loads

---------- module start ----------
local client = {}

client.key = {}
client.mouse = {}
client.enabled = false
client.sessionToken = os.time()
client.sendRate = 35
client.numChannels = 3

client.connected = false
client.id = nil
client.backgrounded = false
client.name = "Player"
client.version = "*"
client.inputSequence = 0
client.remoteInputSequence = 0
client.requestPrediction = false
client.inputCache = List.new()
client.stateBuffer = List.new()
client.lastState = nil
client.snapshot = Buffer.new(10)
client.stateDumpOpts = { comment = false }
client.inputEnabled = true
client.binds = {}

local share = {}
local share_local = {}

client.share = share
client.share_local = share_local

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
    address = address or '127.0.0.1:36963'
    host = enet.host_create()
    if useCompression then
        host:compress_with_range_coder()
    end
    print("CS: client peer started ("..tostring(host)..")")
    print("CS: attempting connection to: "..address)
    host:connect(address, client.numChannels)
end

function client.sendExt(channel, flag, ...)
    if not peer then return end
    peer:send(encode({
        message = { nArgs = select('#', ...), ... },
    }), channel, flag)
end

function client.send(...)
    client.sendExt(nil, nil, ...)
end

function client.sendInput(key, act)
    local bind = client.binds[key]

    if not (bind and peer and client.inputEnabled) then return end

    if not act then
        act = state.DIFF_NIL
    end

    if bind.type == "stream" then
        return
    end

    if bind.type == "toggle" then
        home[bind.input] = act
    end

    if bind.type == "pulse" then
        client.inputSequence = client.inputSequence + 1
        local inputStream = {[bind.input] = act}
        local inputFrame = {
            inputStream = inputStream,
            seq = client.inputSequence
        }
        peer:send(encode(inputFrame), 1, "reliable")
        client.inputCache:push(inputFrame)

        if client.input_response then
            client.input_response(client.id, inputStream, client.inputSequence)
        end
    end
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
    if not host then return end
    -- Service Loop
    while true do
        if not host then break end
        local event = host:service(0)
        if not event then break end

        -- Server connected?
        if event.type == 'connect' then
            -- Ignore this, wait till we receive id (see below)
            client.connect_handler(event)
        end

        -- Server disconnected?
        if event.type == 'disconnect' then
            client.disconnect_handler(event)
        end

        -- Received a request?
        if event.type == 'receive' then
            client.request_handler(event)
        end
    end

end

local timeSinceLastUpdate = 0
function client.postupdate(dt)
    timeSinceLastUpdate = timeSinceLastUpdate + dt
    if timeSinceLastUpdate < 1 / client.sendRate then
        return
    end
    if client.stateBuffer:count() > 0 then
        for index, lastState in client.stateBuffer:walk() do
            state.apply(share_local, lastState)
            state.apply(share, lastState)
            if client.changed then
                client.changed(lastState)
            end
        end
        client.stateBuffer:clear()
    end
    local inputStream
    for key, pressed in pairs(client.key) do
        local bind = client.binds[key]
        if bind and bind.type == "stream" then
            inputStream = inputStream or {}
            inputStream[bind.input] = pressed
        end
    end
    if peer and client.inputEnabled and inputStream then
        client.inputSequence = client.inputSequence + 1
        local inputState = {
            inputStream = inputStream,
            seq = client.inputSequence
        }
        --print(serpent.line(inputStream, client.stateDumpOpts))
        peer:send(encode(inputState), 1, "reliable")
        client.inputCache:push(inputState)

        if client.input_response then
            client.input_response(client.id, inputStream, client.inputSequence)
        end
    end
    if client.tick then
        client.tick(timeSinceLastUpdate)
    end
    if peer then
        -- Send home updates to server
        local diff = home:__diff()
        if diff ~= nil then
            local homeState = {
                diff = diff,
            }
            peer:send(encode(homeState), 1, "reliable")
        end
    end
    home:__flush() -- Make sure to reset diff state after sending!
    if host then
        host:flush() -- Tell ENet to send outgoing messages
    end

    -- Resets the tick's deltatime
    timeSinceLastUpdate = 0
end

function client.request_handler(event)
    local request = decode(event.data)
   	-- SERVER/CLIENT PACKAGE MANAGER
	----------------------------------------------------------------------------
    -- Diff / exact? (do this first so we have it in `.connect` below)
    if request and request.diff then
        client.stateBuffer:push(request.diff)
        local callback
        if client.changing then
            callback = client.changing(request.diff)
        end
        -- Remove all inputs already acknowledged from the buffer
        for index, inputState in client.inputCache:walk() do
            if inputState.seq <= client.remoteInputSequence then
                client.inputCache:remove(inputState)
            end
        end
    end

    if request and request.exact then -- `state.apply` may return a new value
        if client.changing then
            client.changing(request.exact)
        end
        -- Remote
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

        -- Local
        local new_local = state.apply(share_local, request.exact)
        for k, v in pairs(new_local) do
            share_local[k] = v
        end
        for k in pairs(share_local) do
            if not new_local[k] then
                share_local[k] = nil
            end
        end
    end

	-- SERVER/CLIENT AUTHENTICATION
	----------------------------------------------------------------------------
    if request and request.id then
        -- Assign a peer class object to our client
        peer = event.peer
        -- Turn on the connected flags and assing us a ID from server
        client.connected = true
        client.id = request.id

        -- Run the callback function
        if client.connect then
            client.connect()
        end
        print(string.format("CS: assigned player id %s from server", client.id))

        -- Send sessionToken now that we have an id
        -- Also send credentials to the server so he knows who this client is.
        peer:send(encode({
            sessionToken = client.sessionToken,
            name = client.name,
            version = client.version,
        }))
        -- Send the initial input data
        peer:send(encode({
            exact = home:__diff(0, true)
        }), 1, "reliable")
    end

    -- Server is Full?
    if request and request.full then
        if client.full then
            client.full()
        end
    end

        -- INPUT PACKETS
	----------------------------------------------------------------------------
    if request and request.inputAck then
        -- Acknowledged home/input
        client.remoteInputSequence = request.inputAck
        client.requestPrediction = true
    end

    -- SERVER/CLIENT COMMS
	----------------------------------------------------------------------------
    if request and request.message then
        if client.receive then
            client.receive(unpack(request.message, 1, request.message.nArgs))
        end
    end

    if request and request.warning then
        if client.warning then
            client.warning(request.warning)
        end
    end
end

function client.connect_handler(event)
    print("CS: connection attempt")
end

function client.disconnect_handler(event)
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
    print("CS: disconnected from server")

    client.inputCache:clear()
    client.inputSequence = 0
    if client.disconnect then
        client.disconnect()
    end
end


return client

