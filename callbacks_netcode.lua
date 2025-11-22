return function(client)
---------- module start ----------

local home = client.home
local share = client.share
local share_lerp = client.share_lerp

--------------------------------------------------------------------------------------------------
--client callbacks--------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
function client.connect_attempt()
	client.map:clear()
	client.world:clear()

	-- Set up initial values for client
	home.screenh = love.graphics.getWidth()
	home.screenw = love.graphics.getHeight()
	home.attack = false
	home.attack2 = false
	home.attack3 = false
	home.targetX = 0
	home.targetY = 0
end

--- Callback for when client sucessfully connects to server
function client.connect(peer_id)
end

--- Callback for when client disconnects from server
function client.disconnect(reason)
	local LF = require "lib.loveframes"
	LF.SetState()
	client.map:clear()
	client.mode = "lobby"

	if reason then
		client.parse("warning "..reason)
	end
end

-- Callback for when client joins the server
function client.join(peer_id)
	-- Only start the engine on join
	local LF = require "lib.loveframes"
	LF.SetState("game")
	client.mode = "game"

	local player = share.players[peer_id]
	if player then
		--client.camera_lock("players", peer_id)
		client.camera_follow(player)
	end
end

--- Callback for information in sync with server
---@param payload table
function client.changing(payload)
end

--- Callback for information synced with server
---@param payload table
function client.changed(payload)
	if payload.players then
		-- Update players position
		for peer_id in pairs(payload.players) do
			local player
			local player_payload = payload.players[peer_id]
			if share.players and share.players[peer_id] then
				player = share.players[peer_id]
			end
			-- This is the data that will be fed to share anyways, so we use it here
			if player and not client.world:hasItem(player) then
				client.world:add(player, 0, 0, player.size, player.size)
			end

			-- Update collision frames
			if player then
				local half = math.floor(player.size/2)
				client.world:update(player, player.x - half, player.y - half, player.size, player.size)
			end

			-- Update item acquisitions/subtractions
			if client.collect and client.discard then
				if player_payload.i then
					-- Player inventory changed
					for item_type, itemobject in pairs(player_payload.i) do
						if itemobject ~= client.DIFF_NIL then
							client.collect(peer_id, item_type)
						else
							client.discard(peer_id, item_type)
						end
					end
				end

				if player_payload.e then
					-- Player equipment changed
					for item_type, itemobject in pairs(player_payload.e) do
						if itemobject ~= client.DIFF_NIL then
							client.collect(peer_id, item_type)
						else
							client.discard(peer_id, item_type)
						end
					end
				end

				if player_payload.a then
					local armor = player_payload.a
					-- Player armor changed
					if (armor ~= client.DIFF_NIL and armor ~= 0) then
						client.collect(peer_id, player_payload.a)
					else
						--client.discard(peer_id, )
					end
				end
			end

			-- Check if player held item is changed
			if player_payload.ih then
				if client.select then
					client.select(peer_id, player.ih)
				end
			end

		end -- for peer_id in pairs(payload.players)
	end -- if payload.players

	if payload.items then
		-- void
	end
end

function client.peer_connected(peer_id)
end

function client.peer_disconnected(peer_id)
	-- Store it temporarily
	local player = share.players[peer_id]
	local player_s = share_lerp.players[peer_id]

	-- Remove it from the interpolation table
	share_lerp.players[peer_id] = nil
	share.players[peer_id] = nil

	-- Remove it from the collision world if possible
	if player and client.world:hasItem(player) then
		client.world:remove(player)
	end

	player = nil
	player_s = nil
end

function client.peer_joined(peer_id)
	--print(peer_id.. " joined")
end

-- Callback for inputs being pressed
function client.input_response(peer_id, input)
	if input["use"] then
		-- Run it locally
		--client.actions.fire.action(peer_id, home)
	end
end

function client.warning(message)
	client.parse("warning "..message)
end

---Callback for messages/packets received by server
---@param message string
function client.receive(message)
	-- Send the message to the action parser
    client.parse(message)
	--print(string.format("©236118000Parse: %s", message))
end


function client.tick(dt)
	--print(serpent.line(client.key, client.stateDumpOpts))
	if client.joined then
		client.predict_player(client.id, dt)
    end
end

---------- module end ------------
end