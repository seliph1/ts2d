--- Client base framework
local b				= require "lib.battery"
local Map 			= require "mapengine"
local client 		= require "lib.cs"


client.enabled 			= true
client.width 			= 800
client.height 			= 600
client.scale 			= false
client.mode 			= "lobby"
client.map 				= Map.new(50, 50)
client.debug_level		= 0

client.input_enabled 	= false

client.content = require "enum"
client.actions = require "actions" (client)
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
client.cache = {
	tween_speed = 20,
	players = {},
	bullets = {},
}
client.key = {}
client.gfx = {
	itemlist = {};
	hud = {};
	objects = {};
	player = {};
	ui = {};
}
require "loader" (client)

--- Table that gets info from server
---@class table
--- @field bullets table
--- @field players table
--- @field items table
--- @field scores table
local share = client.share

---@class userdata
--- @field targetX integer position of our client
--- @field targetY integer position of our client
--- @field wantShoot boolean variable that stores our mouse keypresses
--- @field move table direction vector
local home = client.home

--------------------------------------------------------------------------------------------------
--love callbacks----------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------

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
    if button == 1 then
        home.wantShoot = true
    end

	if button == 2 then
		--local diff_x = (client.width/2 - home.targetX)
		--local diff_y = (client.height/2 - home.targetY)

		--local pos_x = client.camera.x - diff_x
		--local pos_y = client.camera.y - diff_y

		--client.send(string.format("setpos %s %s", pos_x, pos_y))
	end
end

--- Callback for mouse button releasing on screen
---@param x number
---@param y number
---@param button number
function client.mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        home.wantShoot = false
    end

	if button == 2 then
		local tx, ty = client.map:mouseToMap(x, y)
		--client.map:spawn_effect("rain", tx, ty)
		client.map:spawn_effect("hitscan", tx, ty)
	end
end

--- Callback for key press event
---@param k string Key pressed
function client.keypressed(k)
	client.key[k] = true
	if client.connected then
		if k == "return" then
			local ui = require "core.interface.ui"
			local LF = require "lib.loveframes"

			if ( LF.inputobject or LF.hoverobject) then return end

			local bool = ui.chat_input_frame:GetVisible()
			ui.chat_input_frame:SetVisible(not bool)
		end
	end
end

--- Callback for key release event
---@param k string Key released
function client.keyreleased(k)
	client.key[k] = false
	if client.connected then
	end
end

function client.movement_handle(dt)
	local x, y = b.get_vector("a", "d", "w", "s")

	home.move_v = x
	home.move_h = y
end

---Main game loop
---@param dt number
function client.update(dt)
	client.movement_handle(dt)


	client.preupdate(dt)
	if (client.mode == "game" or client.mode == "editor") and client.map then
		client.camera_move(dt)
		client.camera_tween(dt)
		client.map:scroll(client.camera.x, client.camera.y)
		client.map:update(dt)
	end
	if client.connected then
		-- Move players
        for id, player in pairs(share.players) do
			client.move_player(id, player, dt)
        end

		-- Move bullets
        for id, bullet in pairs(share.bullets) do
            client.move_bullet(id, bullet, dt)
        end
    end
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
		local label = string.format("Camera: %dpx|%dpx  Ping: %s  FPS: %s  Target: %d|%d   Memory: %.2f MB",
			client.camera.x,
			client.camera.y,
			client.getPing(),
			love.timer.getFPS(),
			client.home.targetX,
			client.home.targetY,
			collectgarbage("count") / 1024
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
function client.disconnect()
	local LF = require "lib.loveframes"
	LF.SetState()
	client.map:clear()
	client.mode = "lobby"
end

--- Callback for information in sync with server
---@param payload table
function client.changing(payload)
end

--- Callback for information synced with server
---@param payload table
function client.changed(payload)
	for category, data in pairs(payload) do
		if category == "items" then
			client.map:update_items(share, client)
			--client.map._updateRequest = true
			-- This is the entire itemdata payload received by the server
			--[[
			for key, item in pairs(data) do
				print(key, item.it, item.x, item.y)
			end
			]]
		end
	end
end

---Callback for messages/packets received by server
---@param message string
function client.receive(message)
	-- Send the message to the command parser
    client.parse(message)
	print(string.format("©236118000Parse: %s", message))
end

--- Client loading routine at the start of program
function client.load()
	-- Set up initial values for client
    home.targetX = 0
    home.targetY = 0
    home.wantShoot = false
	home.move_h = 0
	home.move_v = 0
	home.name = "Mozilla"
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

--- Move player in smooth intervals
---@param id number
---@param player table player object table
---@param dt number delta time
function client.move_player(id, player, dt) -- `home` is used to apply controls if given
	-- Receive the actual position from server
	local x = player.x
	local y = player.y

	-- Get the last position received from cache
	client.cache.players[id] = client.cache.players[id] or {x=player.x, y=player.y}
	local cache = client.cache.players[id]
	local cx = cache.x
	local cy = cache.y
	if math.abs(cache.x - player.x) > 16 or math.abs(cache.y - player.y) > 16 then
		cache.x = x
		cache.y = y
	else
		-- Interpolate the movement
		cache.x = b.lerp(cx, x, client.cache.tween_speed * dt)
		cache.y = b.lerp(cy, y, client.cache.tween_speed * dt)
	end
end

--- Bullet movement updater
---@param id number
---@param bullet table Bullet object
---@param dt number Delta time
function client.move_bullet(id, bullet, dt)
	-- Receive the actual position from server
	local x = bullet.x
	local y = bullet.y

	-- Remove old data if applicable
	if client.cache.bullets[id] and not share.bullets[id] then
		client.cache.bullets[id] = nil
	end

	-- Get the last position received from cache
	client.cache.bullets[id] = client.cache.bullets[id] or {x=bullet.x, y=bullet.y}
	local cache = client.cache.bullets[id]
	local cx = cache.x
	local cy = cache.y

	if math.abs(cache.x - bullet.x) > 16 or math.abs(cache.y - bullet.y) > 16 then
		cache.x = x
		cache.y = y
	end

	-- Interpolate the movement
	cache.x = b.lerp(cx, x, 100 * dt)
	cache.y = b.lerp(cy, y, 100 * dt)
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
		local diff_x = (client.width/2 - home.targetX)/8
		local diff_y = (client.height/2 - home.targetY)/8
		client.camera.tx = share.players[client.id].x - diff_x
		client.camera.ty = share.players[client.id].y - diff_y
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
		-- Bullet render
		client.map:draw_bullets(share, home, client)
		-- Draw items on the ground
		client.map:draw_items(share, client) 
		-- Player render
		--client.map:draw_players(share, home, client)
		client.map:draw_playersc(client)
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