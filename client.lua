--- Client base framework
local b				= require "lib.battery"
local Map 			= require "mapengine"
local client 		= require "lib.cs"
local serpent 		= require "lib.serpent"
local bump			= require "lib.bump"

client.enabled 			= true
client.version 			= "v1.0.1"
client.width 			= 800
client.height 			= 600
client.scale 			= false
client.mode 			= "lobby"
client.map 				= Map.new(50, 50)
client.world			= bump.new()
client.debug_level		= 0
client.shootTimer 		= 0

client.content = require "enum"
client.actions = require "actions" (client)
client.binds   = require "binds" (client)
client.canvas = love.graphics.newCanvas()
client.camera = {
	x = 0,
	y = 0,
	tx = 0,
	ty = 0,
	snap_pointer = {category = nil, id = nil},
	snap_enabled = false,
	speed = 500, -- pixel/frame
	tween_speed = 15, -- pixel/frame
}

client.gfx = {
	itemlist = {};
	hud = {};
	objects = {};
	player = {};
	ui = {};
}
require "loader" (client)

--- Table that gets info from server
---@class Share
--- @field bullets table
--- @field players table
--- @field items table
--- @field scores table
local share = client.share

---@class Share
local share_local = client.share_local

---@class Share
local share_lerp = client.share_lerp
share_lerp = {
	players = {},
	entities = {},
	bullets = {},
	items = {},
	scores = {}
}
client.lerp_speed = 30

---@class userdata
--- @field targetX integer position of our client
--- @field targetY integer position of our client
--- @field wantShoot boolean variable that stores our mouse keypresses
--- @field move table direction vector
local home = client.home

local DIFF_NIL = client.DIFF_NIL
--------------------------------------------------------------------------------------------------
--love callbacks----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
function client.resize(w, h)
	home.screenw = w
	home.screenh = h
end

--- Client loading routine at the start of program
function client.load()
	-- Set up initial values for client
	home.screenh = love.graphics.getWidth()
	home.screenw = love.graphics.getHeight()
	home.attack = false
	home.attack2 = false
	home.attack3 = false
end

--- Callback for mouse movement on screen
---@param x number
---@param y number
function client.mousemoved(x, y)
    -- Transform mouse coordinates according to display centering and scaling
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local rel_x = x - (w - client.width)/2
	local rel_y = y - (h - client.height)/2
	-- Dont go less than 0 or more than 600/800 even if mouse is out of bounds
	local abs_x = math.min(math.max(rel_x, 0), client.width)
	local abs_y = math.min(math.max(rel_y, 0), client.height)
	-- Update mouse position
	home.targetX = abs_x
	home.targetY = abs_y
end

--- Callback for mouse clicking on screen
---@param x number
---@param y number
---@param button number
function client.mousepressed(x, y, button, istouch, presses)
	if not client.key[button] then
		client.sendInput(button, true)
	end
	client.key[button] = true
	----------------------------------------------------------------
	local mx, my = client.map:mouseToMap(love.mouse.getPosition())
end

--- Callback for mouse button releasing on screen
---@param x number
---@param y number
---@param button number
function client.mousereleased(x, y, button, istouch, presses)
	if client.key[button] then
		client.sendInput(button, nil)
	end
	client.key[button] = nil
	----------------------------------------------------------------

	if button == 2 then
		local tx, ty = client.map:mouseToMap(x, y)
	end
end

function client.wheelmoved(x, y)
	local button
	if y == 1 then
		button = "mwheelup"
	elseif y == - 1 then
		button = "mwheeldown"
	end
	client.sendInput(button, true)
end

--- Callback for key press event
---@param key string Key pressed
function client.keypressed(key)
	if not client.key[key] then
		client.sendInput(key, true)
	end
	client.key[key] = true
end

--- Callback for key release event
---@param key string Key released
function client.keyreleased(key)
	if client.key[key] then
		client.sendInput(key, nil)
	end
	client.key[key] = nil
end

---Main game loop
---@param dt number
function client.update(dt)
	client.preupdate(dt)
	if (client.mode == "game" or client.mode == "editor") and client.map then
		client.camera_move(dt)
		client.camera_tween(dt)
		client.map:scroll(client.camera.x, client.camera.y)
		client.map:update(dt)
	end
	client.frame(dt)
	client.postupdate(dt)

	-- Update visual effects on client after data transfer take effect
	if (client.mode == "game" or client.mode == "editor") and client.map then
		client.render()
	end
end

---Main game render loop
function client.draw()
	-- Draw background if it's in lobby mode
	if client.mode == "lobby" then
		client.draw_splash(0, 0)
	end

	if client.mode == "game" or client.mode == "editor" then
		-- Center and scale display
		local ox = 0.5 * (love.graphics.getWidth() - client.width)
		local oy = 0.5 * (love.graphics.getHeight() - client.height)

		if client.scale then
			love.graphics.push()
			love.graphics.setDefaultFilter("linear", "linear")
			love.graphics.scale(love.graphics.getWidth() / client.width, love.graphics.getHeight() / client.height)
			love.graphics.draw(client.canvas, -ox, -oy)
			love.graphics.pop()
		else
			love.graphics.draw(client.canvas, 0, 0)
		end
	end

	-- Crosshair debug
	if client.debug_level > 0 then
		-- Draw middle crosshair
		love.graphics.line(love.graphics.getWidth()/2-5, love.graphics.getHeight()/2, love.graphics.getWidth()/2+5, love.graphics.getHeight()/2)
		love.graphics.line(love.graphics.getWidth()/2, love.graphics.getHeight()/2-5, love.graphics.getWidth()/2, love.graphics.getHeight()/2+5)
	end

	if client.debug_level == 2 then
		-- Advanced debug
		local x = client.camera.x or 0
		local y = client.camera.y or 0
		local ping = client.getPing() or 0
		local fps = love.timer.getFPS()
		local targetX = client.mouse.x or 0
		local targetY = client.mouse.y or 0
		local memory = (collectgarbage "count" / 1024) or 0
		local pendingInputs = client.inputCache:count() or 0

		local label = string.format("Camera: %dpx|%dpx  Ping: %s  FPS: %s  Target: %d|%d   Memory: %.2f MB  Pending Inputs: %s",
			x, y, ping, fps, targetX, targetY, memory, pendingInputs
		)

		love.graphics.printf(label, 0, love.graphics.getHeight()-20, love.graphics.getWidth(), "center")
	elseif client.debug_level == 1 then
		-- Simple debug
		local label = string.format("FPS: %s  Memory: %.2f MB",
			love.timer.getFPS(),
			collectgarbage("count") / 1024
		)
		love.graphics.printf(label, 0, love.graphics.getHeight()-20, love.graphics.getWidth(), "center")
	else
		-- void
	end
end

--------------------------------------------------------------------------------------------------
--client callbacks--------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
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
		client.camera_lock("players", peer_id)
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
		end
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

--- Client command parser
--- @param str string
function client.parse(str)
    local args = {}
	for word in string.gmatch(str, "%S+") do
		table.insert(args, word)
	end

	local action_id = args[1]
	local actions = client.actions
	if actions[ action_id ] then
		local action_object = actions[ action_id ]
		if action_object.action then
			local status = action_object.action( unpack(args,2) )
		end
	else
		print(string.format("Unknown command: %s", str))
	end
end

function client.tick(dt)
	--print(serpent.line(client.key, client.stateDumpOpts))
	if client.joined then
		client.predict_player(client.id, dt)
    end
end

function client.frame(dt)
	if client.joined then
		client.snapshot_lerp(dt)
	end
end

function client.snapshot_lerp(dt)
	local lerp_flags = {
		x = true,
		y = true,
		targetX = true,
		targetY = true,
	}

	local lerp_fields = {
		players = true
	}

	for player_id, player in pairs(share.players) do
		share_lerp.players[player_id] = share_lerp.players[player_id] or {}

		for property, value in pairs(player) do
			if lerp_flags[property] then
				local lerp_value = share_lerp.players[player_id][property] or value
				-- Apply lerp
				share_lerp.players[player_id][property] = b.lerp(lerp_value, value, client.lerp_speed * dt)
			else
				share_lerp.players[player_id][property] = value
			end
		end
	end
end

--- Move player in smooth intervals
---@param peer_id number
function client.predict_player(peer_id, dt) -- `home` is used to apply controls if given
	-- Check if its own player id, and is connected
	if not( client.id == peer_id and client.joined ) then return end

	-- Store player object
	local player_local = share_local.players[peer_id]
	local player = share.players[peer_id]

	-- Check if the player object exists
	if not (player and player_local) then return end

	-- Apply input results to player
	player.x = player_local.x
	player.y = player_local.y
	for index, inputState in client.inputCache:walk() do
		client.apply_input_to_player(inputState.inputStream, client.id)
	end

	-- Check if the player is able to attack
	player.attack_cooldown = player.attack_cooldown or 0
	local want_to_attack = false
	if player.attack_cooldown > 0 then
		player.attack_cooldown = player.attack_cooldown - dt
	else
		if home.attack == true then
			want_to_attack = true
		end
	end

	if want_to_attack == true then
		local cooldown = client.attack(client.id, dt)
		if cooldown > 0 then
			player.attack_cooldown = cooldown
		end
	end
end

function client.attack(peer_id, dt)
	local itemheld = client.get_item_held(peer_id)
	local itemdata = client.get_item_data(itemheld)
	if not itemdata then return 0 end

	if itemdata.category == "primary" or itemdata.category == "secondary" then
		-- Frame delay of this weapon
		local rate_of_fire = itemdata.rate_of_fire or 9

		-- True delay of this weapon
		local seconds = rate_of_fire * dt

		-- Simulate locally that we fired a weapon
		client.actions.fire.action(client.id, home)

		return seconds
	end
	return 0
end

function client.get_item_held(peer_id)
	local player = share.players[peer_id]
	if not player then return 0 end
	local itemheld = player.ih or 0
	return itemheld
end

function client.get_item_data(item_type)
	local itemdata = client.content.itemlist[item_type]
	if itemdata then
		return itemdata
	end
end

function client.apply_input_to_player(input, peer_id)
	local player = share.players[peer_id]
	local map = client.map
	if not (player and map) then return end

	-- Initialize forces
	local h, v, w = 0, 0, 1
	if input["forward"] then v = -1 	end
	if input["back"] 	then v =  1 	end
	if input["left"] 	then h = -1 	end
	if input["right"] 	then h =  1 	end
	if input["walk"] 	then w =  0.5 	end

	if v ~= 0 or h ~= 0 then
		-- Calculate magnitude
		local mag = math.sqrt(v*v + h*h)
		local scale
		if mag == 0 then
			v, h = 0, 0
		else
			scale = 1/mag
			v, h = v * scale, h * scale
		end
		client.apply_forces_to_player(peer_id, v, h, w)
	end
end

function client.apply_forces_to_player(peer_id, v, h, w)
	local player = share.players[peer_id]
	local map = client.map
	if not (player and map) then return end

	-- Multiply vector by velocity and walk factor
	-- and store the forces
	local dx = player.s * h * w
	local dy = player.s * v * w

	-- Slide square object into the map
	local future_x, future_y = map:moveWithSliding(player.size, player.x, player.y, dx, dy)

	-- Get the player half size
	local half = math.floor(player.size/2)

	-- Calculate player colliding with other objects
	client.world:update(player, player.x - half, player.y - half, player.size, player.size)

	-- Apply the collision result
	local filter = client.player_collision_filter
	local current_x, current_y, collisions, length = client.world:move(player, future_x - half, future_y - half, filter)
	player.x = current_x + half
	player.y = current_y + half

	-- Collision handler
	for i = 1, length do
		local collision = collisions[i]
		local _type 	= collision.type
		local object 	= collision.other
		local itemRect 	= collision.itemRect
		local otherRect = collision.otherRect
		local move 		= collision.move
		local normal 	= collision.normal
		local ti 		= collision.ti
		local overlaps 	= collision.overlaps
	end
end

function client.player_collision_filter(item, other)
	if item.ct == 1 then
		if other.ct == 2 then
			return "cross" -- Ignore physics and register the collision
		elseif other.ct == 1 then
			return "slide" -- Apply physics to other players
		end
	end
end

--- Cast a ray that collides with map, players, items and entities. ---
--- Returns the first object that collided with this segment
function client.raycast(x1, y1, x2, y2)
	if not client.map then return false end

	local start_x, start_y = x1, y1
	local impact_x, impact_y, hit = client.map:hitscan(x1, y1, x2, y2)

	local item_info, len = client.world:querySegmentWithCoords(start_x, start_y, impact_x, impact_y)
	for i=1, len do
		local info = item_info[i]

		-- Update the values for the first object impacted
		impact_x = info.x1
		impact_y = info.y1
		hit = true
		-- Breaks on the first impact
		break
	end

	return impact_x, impact_y, hit
end

--- Cast a ray that dont collide with anything, but register intersection
--- with map, players, items and entities.
--- Returns a list of tiles and objects that intersected with this segment
function client.raycast_t(x1, y1, x2, y2)
end


--- Camera movement vector function
---@param dt number Delta time
function client.camera_move(dt)
	-- Speed
	local s = client.camera.speed * dt
	if client.key.space then
		s = s * 5
	end
	-- Vector
	local vx, vy = 0, 0
	if (client.key.up) then vy = -s end
	if (client.key.left) then vx = -s end
	if (client.key.down) then vy = s end
	if (client.key.right) then vx = s end
	-- Vector apply
	client.camera.tx = client.camera.tx + vx
	client.camera.ty = client.camera.ty + vy

	local snap_pointer = client.camera_pointer()

	if snap_pointer and snap_pointer.x and snap_pointer.y then
		local x = snap_pointer.x
		local y = snap_pointer.y
		--local diff_x = (client.width/2 - home.targetX)/2 -- 0
		--local diff_y = (client.height/2 - home.targetY)/2 -- 0
		local diff_x = 0
		local diff_y = 0
		client.camera.tx = x - diff_x
		client.camera.ty = y - diff_y
	end
end

function client.camera_lock(category, id)
	local snap_pointer = client.camera.snap_pointer
	snap_pointer.category = category
	snap_pointer.id = id
end

function client.camera_pointer()
	local snap_pointer = client.camera.snap_pointer
	local category = snap_pointer.category
	local id = snap_pointer.id

	if client.share[category] and client.share[category][id] then
		return client.share[category][id]
	end
	return nil
end

---Camera interpolated movement function
---@param dt number Delta time
function client.camera_tween(dt)
	client.camera.x = b.lerp(client.camera.x, client.camera.tx, client.camera.tween_speed * dt)
	client.camera.y = b.lerp(client.camera.y, client.camera.ty, client.camera.tween_speed * dt)
end

function client.draw_splash(ox, oy)
	local splash_art = client.gfx.ui["gfx/splash.bmp"]
	local splash_width = love.graphics.getWidth() / splash_art:getWidth()
	local splash_height = love.graphics.getHeight() / splash_art:getHeight()
	love.graphics.draw(splash_art, ox, oy, 0, splash_width, splash_height)
end

function client.render()
	love.graphics.push('all')
	love.graphics.setCanvas(client.canvas)

    -- Center display
    local ox = 0.5 * (love.graphics.getWidth() - client.width)
	local oy = 0.5 * (love.graphics.getHeight() - client.height)

	-- Set the boundaries to render engine
	love.graphics.setScissor(ox, oy, client.width, client.height)

	if (client.mode == "game" or client.mode == "editor") and client.map then
		client.map:draw_floor()
		client.map:draw_entities()
	end

    if client.joined then
		-- Draw items on the ground
		client.map:draw_items(share, client)
		-- Player render
		client.map:draw_players(share_lerp, client)
    end

	if (client.mode == "game" or client.mode == "editor") and client.map then
		client.map:draw_ceiling()
		client.map:draw_effects()
	end

	-- Resets scissoring and canvas
	love.graphics.pop()
	love.graphics.setCanvas()
end

--- Returns the client object to the main code block
return client