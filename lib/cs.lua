local enet      = require 'enet'
local state     = require 'lib.state'
local cbor      = require 'lib.cbor'
local serpent   = require 'lib.serpent'
local List      = require 'lib.list'
local Buffer    = require 'lib.buffer'

local encode = cbor.encode
local decode = cbor.decode

---------- module start ----------
local client = {}

client.key = {}
client.mouse = {}
client.enabled = false
client.sessionToken = os.time()
client.sendRate = 30
client.tickRate = 60
client.packet_mean = 0
client.packet_last = 0
client.numChannels = 3

client.connected = false
client.joined = false
client.id = nil
client.dt = 0
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
local share_lerp = {}

client.share = share
client.share_local = share_local
client.share_lerp = share_lerp

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
    client.reset()

    address = address or '127.0.0.1:36963'
    host = enet.host_create()
    if useCompression then
        host:compress_with_range_coder()
    end
    print("CS: client peer started ("..tostring(host)..")")
    print("CS: attempting connection to: "..address)
    host:connect(address, client.numChannels)
end

function client.reset()
    client.connected = false
    client.joined = false
    client.id = nil
    for k in pairs(share) do
        share[k] = nil
    end
    for k in pairs(home) do
        home[k] = nil
    end
    host = nil
    peer = nil

    client.inputSequence = 0
    client.remoteInputSequence = 0

    client.stateBuffer:clear()
    client.inputCache:clear()
    client.snapshot:clear()
    client.inputSequence = 0
    client.lastState = nil

    collectgarbage("collect")
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
    if not client.joined then return end
    local bind = client.binds[key]
    if not (bind and peer and client.inputEnabled) then return end
    act = act or state.DIFF_NIL

    if bind.type == "stream" then
        -- Do nothing.
        -- This is handled in client.postupdate
        return
    end

    if bind.type == "toggle" then
        -- This is handled in client.postupdate
        -- As a "home" state change
        home[bind.input] = act
        return
    end

    if bind.type == "pulse" then
        -- Send keypresses as a one-time pulse action.
        -- Doesn't overlap with stream-like actions.
        -- Also sends keyrelease pulses
        client.inputSequence = client.inputSequence + 1
        local inputStream = {[bind.input] = act}
        local inputFrame = {
            inputStream = inputStream,
            seq = client.inputSequence
        }
        -- Runs the response client-side, should we ever need that
        -- Also don't send anything if the input is confirmed to be false
        if client.input_response then
            -- 19/10/2025: we needed that.
            if act == state.DIFF_NIL then
                client.input_response(client.id, {}, client.inputSequence)
            else
                client.input_response(client.id, inputStream, client.inputSequence)
            end
        end
        -- Sends input to server
        peer:send(encode(inputFrame), 1, "reliable")

        -- Stores the inputState so we can later do some client prediction
        client.inputCache:push(inputFrame)
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

        -- Connected with server?
        if event.type == 'connect' then
            -- Ignore this, wait till we receive id (see below)
            client.connect_handler(event)
        end

        -- Disconnected from server?
        if event.type == 'disconnect' then
            client.disconnect_handler(event)
        end

        -- Received a request?
        if event.type == 'receive' then
            client.request_handler(event)
        end
    end

end

local accumulator = 0
function client.postupdate(dt)
    accumulator = accumulator + dt
    local tickStep = 1 / client.sendRate
    while accumulator >= tickStep do
        client.sendState(tickStep)
        accumulator = accumulator - tickStep
    end
end

function client.sendState(dt)
    -- Dont send any input updates if not joined.
    -- Likewise, server wont accept these inputs.
    if not client.joined then return end


    -- Apply all of the changed states at once from the buffer in a single tick.
    if client.stateBuffer:count() > 0 then
        for index, lastState in client.stateBuffer:walk() do
            if client.changing then
                client.changing(lastState)
            end
            state.apply(share_local, lastState)
            state.apply(share, lastState)
            if client.changed then
                client.changed(lastState)
            end
        end
        client.stateBuffer:clear()
    end

    -- Adds from client keypresses to the input stream table
    local inputStream
    for key, pressed in pairs(client.key) do
        local bind = client.binds[key]
        -- There are tree types of inputs
        -- "Stream" type input refers to a line of keys pressed at a time, continually
        if bind and bind.type == "stream" then
            inputStream = inputStream or {}
            inputStream[bind.input] = pressed
        end
    end

    -- Runs through the table and sends the input stream to server
    if peer and client.inputEnabled and inputStream then
        client.inputSequence = client.inputSequence + 1
        local inputState = {
            inputStream = inputStream,
            seq = client.inputSequence
        }

        -- Runs the response client-side, should we ever need that
        if client.input_response then
            client.input_response(client.id, inputStream, client.inputSequence)
        end

        -- Sends input to server
        peer:send(encode(inputState), 1, "reliable") --print(serpent.line(inputStream))

        -- Stores the inputState so we can later do some client prediction
        client.inputCache:push(inputState)
    end

    -- Run the tick callback
    if client.tick then
        client.tick(dt)
    end

    -- Send home updates to server
    if peer then
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
end

function client.request_handler(event)
    local request = decode(event.data)
    if not request then return end

    --print(string.format("%sb: %s", #event.data, event.data))

   	-- SERVER/CLIENT PACKAGE MANAGER
	----------------------------------------------------------------------------
    -- Diff / exact? (do this first so we have it in `.connect` below)
    if request.diff then
        client.stateBuffer:push(request.diff)
        -- Remove all inputs already acknowledged from the buffer
        for index, inputState in client.inputCache:walk() do
            if inputState.seq <= client.remoteInputSequence then
                client.inputCache:remove(inputState)
            end
        end
        -- The "changed" callback is done at the end of tick, for consistency
    end

    if request.exact then -- `state.apply` may return a new value
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
    if request.id then
        -- Assign a peer class object to our client
        peer = event.peer
        -- Turn on the connected flags and assing us a ID from server
        client.connected = true
        client.id = request.id

        -- Run the callback function
        if client.connect then
            client.connect(client.id)
        end
        print(string.format("CS: assigned player id %s from server", client.id))

        -- Send sessionToken now that we have an id
        -- Also send credentials to the server so he knows who this client is.
        peer:send(encode({
            sessionToken = client.sessionToken,
            name = client.name,
            version = client.version,
        }))

    end

    if request.versionAck then
        -- Server acknowledged our client version.
        -- We now send the world request
        peer:send(encode({
            dataRequest = true,
        }))
    end

    if request.joinAck then
        -- Everything is ready, so we trigger the final flag and the join callback
        if client.join then
            client.join(client.id)
        end
        client.joined = true

        -- And we also send input data to server
        peer:send(encode({
            exact = home:__diff(0, true)
        }), 1, "reliable")
    end

    if request.full then
        -- Server is Full, as said by the server
        -- So, trigger some callbacks to our client.
        if client.full then
            client.full()
        end
    end

    -- INPUT PACKETS
	----------------------------------------------------------------------------
    if request.inputAck then
        -- Acknowledged home/input
        -- Trigger some flags on the prediction system inherited from this lib.
        client.remoteInputSequence = request.inputAck
        client.requestPrediction = true
    end

    -- SERVER/CLIENT COMMS
	----------------------------------------------------------------------------
    if request.message then
        -- We received a message from server
        -- Let's translate this message and send it to whatever callback might be relevant.
        if client.receive then
            client.receive(unpack(request.message, 1, request.message.nArgs))
        end
    end

    if request.warning then
        -- Sever sent us a warning.
        -- Better display it to this client.
        if client.warning then
            client.warning(request.warning)
        end
    end

    if request.peer_connected then
        if client.peer_connected then
            client.peer_connected(request.peer_connected)
        end
    end

    if request.peer_disconnected then
        if client.peer_disconnected then
            client.peer_disconnected(request.peer_disconnected)
        end
    end

    if request.peer_joined then
        if client.peer_joined then
            client.peer_joined(request.peer_joined)
        end
    end
end

function client.connect_handler(event)
    if client.connect_attempt then
        client.connect_attempt()
    end

    print("CS: connection attempt")
end

function client.disconnect_handler(event)
    client.connected = false
    client.joined = false
    client.id = nil
    for k in pairs(share) do
        share[k] = nil
    end
    for k in pairs(home) do
        home[k] = nil
    end
    host = nil
    peer = nil
    client.inputCache:clear()
    client.inputSequence = 0
    if client.disconnect then
        client.disconnect()
    end
    print("CS: disconnected from server")
end

function client.void(object)
    return (object == state.DIFF_NIL)
end

function client.attribute(attribute)
    local value = home[attribute]
    if value == state.DIFF_NIL then
        return nil
    else
        return value
    end
end
client.attr = client.attribute


client.DIFF_NIL = state.DIFF_NIL
return client

