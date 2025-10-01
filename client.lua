--- Client base framework
local b				= require "lib.battery"
local Map 			= require "mapengine"
local client 		= require "lib.cs"
local serpent 		= require "lib.serpent"
local bump			= require "lib.bump"

client.enabled 			= true
client.version 			= "v1.0.0"
client.width 			= 800
client.height 			= 600
client.scale 			= false
client.mode 			= "lobby"
client.map 				= Map.new(50, 50)
client.world			= bump.newWorld()
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
	snap_pointer = 0,
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

---@class userdata
--- @field targetX integer position of our client
--- @field targetY integer position of our client
--- @field wantShoot boolean variable that stores our mouse keypresses
--- @field move table direction vector
local home = client.home

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
	local mx, my = client.map:mouseToMap(love.mouse.getPosition())
    if button == 1 then
		--if client.shootTimer = 
    end
	if button == 2 then
	end
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

    if button == 1 then
    end

	if button == 2 then
		local tx, ty = client.map:mouseToMap(x, y)
	end
end

--- Callback for key press event
---@param key string Key pressed
function client.keypressed(key)
	if not client.key[key] then
		client.sendInput(key, true)
	end
	client.key[key] = true

	if client.connected then
		if key == "return" then -- Enter pressed
			local ui = require "core.interface.ui"
			local LF = require "lib.loveframes"

			if ( LF.inputobject or LF.hoverobject ) then return end

			local bool = ui.chat_input_frame:GetVisible()
			ui.chat_input_frame:SetVisible(not bool)

			client.inputEnabled = bool
		end
	end
end

--- Callback for key release event
---@param key string Key released
function client.keyreleased(key)
	if client.key[key] then
		client.sendInput(key, nil)
	end
	client.key[key] = nil
	if client.connected then
	end
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
function client.connect()
	local LF = require "lib.loveframes"
	LF.SetState("game")
	client.mode = "game"
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

--- Callback for information in sync with server
---@param payload table
function client.changing(payload)
	
end

--- Callback for information synced with server
---@param payload table
function client.changed(payload)
end

-- Callback for inputs being pressed
function client.input_response(peer_id, inputStream, seq)
end

function client.warning(message)
	client.parse("warning "..message)
end

---Callback for messages/packets received by server
---@param message string
function client.receive(message)
	-- Send the message to the action parser
    client.parse(message)
	print(string.format("©236118000Parse: %s", message))
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
	if client.connected then
		client.predict_player(client.id)
    end
end

function client.frame(dt)
	if client.connected then
		client.snapshot_lerp(dt)
	end
end

client.share_lerp = {
	players = {},
	--entities = {},
}
client.lerp_speed = 30
local share_lerp = client.share_lerp
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
function client.predict_player(peer_id) -- `home` is used to apply controls if given
	if client.id == peer_id and client.connected then
		local player_local = share_local.players[peer_id]
		local player = share.players[peer_id]

		player.x = player_local.x
		player.y = player_local.y
		for index, inputState in client.inputCache:walk() do
			client.apply_input_to_player(inputState.inputStream, player)
		end



		-- Shoot timer fake
		if client.shootTimer <= 0 then
			client.shootTimer = 3
		else
			client.shoottimer
		end

	end
end

function client.apply_input_to_player(input, player)
	local h, v = 0, 0
	local map = client.map
	if input["forward"] then v = -1 end
	if input["back"] then v = 1 end
	if input["left"] then h = -1 end
	if input["right"] then h = 1 end
	-- Magnitude
    local mag = math.sqrt(v*v + h*h)
	local scale
	if mag == 0 then
		v, h = 0, 0
	else
		scale = 1/mag
		v, h = v * scale, h * scale
	end
	-- Multiply vector by velocity and walk factor
	local w = 1
	if input["walk"] then
		w = 0.5
	end
	local dx = player.s * h * w
	local dy = player.s * v * w

	-- Slide square object into the map
	if map then
		local future_x, future_y = map:moveWithSliding(player.size, player.x, player.y, dx, dy)
		player.x = future_x
		player.y = future_y
	end
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

	if client.connected then
		local players = share.players
		local x = players[client.id].x or 0
		local y = players[client.id].y or 0
		local diff_x = (client.width/2 - home.targetX)/2
		local diff_y = (client.height/2 - home.targetY)/2
		--local diff_x = 0
		--local diff_y = 0
		client.camera.tx = x - diff_x
		client.camera.ty = y - diff_y
	end
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

    if client.connected then
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