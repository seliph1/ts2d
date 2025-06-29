local cs 		= require "lib/cs"
local b			= require "lib.battery"
local enum      = require "enum"
local MapObject = require "mapengine"

require "lib/lovefs/lovefs"
local fs = lovefs()
if love.filesystem.isFused() then
	fs:cd(love.filesystem.getSourceBaseDirectory() )
else
	fs:cd(love.filesystem.getSource() )
end
--- Client base framework
--- @class client
--- @field home table
--- @field share table
--- @field connected function
--- @field preupdate function
--- @field postupdate function
--- @field getPing fun():number
--- @field id number
--- @field send fun(message:string)
--- @field start fun(address:string)
local client = cs.client
client.enabled = true
client.map = MapObject.new(50, 50)
client.content = enum
client.width = 800
client.height = 600
client.scale = 1
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
}
client.key = {}
client.gfx = {
	itemlist = {};
	hud = {};
	objects = {};
	player = {};
}

--- Table that gets info from server
--- @class share
--- @field bullets table
--- @field players table
--- @field items table
--- @field scores table
local share = client.share

--- Use `home` to store control info so the server can see it
--- @class home
--- @field targetX integer position of our client
--- @field targetY integer position of our client
--- @field wantShoot boolean variable that stores our mouse keypresses
--- @field move table direction vector
local home = client.home

do
	for _, item in pairs(client.content.itemlist) do
		local path = item.common_path
		local full_path_d = path .. item.dropped_image
		local full_path_h = path .. item.held_image
		local full_path_k = path .. item.kill_image
		local full_path = path .. item.display_image

		if item.dropped_image ~= "" and fs:isFile(full_path) then
			client.gfx.itemlist[full_path] = fs:loadImage(full_path)
		end
		if item.held_image ~= "" and fs:isFile(full_path_d) then
			client.gfx.itemlist[full_path_d] = fs:loadImage(full_path_d)
		end
		if item.display_image ~= "" and fs:isFile(full_path_h) then
			client.gfx.itemlist[full_path_h] = fs:loadImage(full_path_h)
		end
		if item.kill_image ~= "" and fs:isFile(full_path_k) then
			client.gfx.itemlist[full_path_k] = fs:loadImage(full_path_k)
		end
	end

	for name, player in pairs(client.content.player) do
		client.gfx.player[name] = client.gfx.player[name] or {}
		local texture = fs:loadImage(player.path)
		client.gfx.player[name].texture = texture
		for entry, value in pairs(player.stance) do
			client.gfx.player[name][entry] = love.graphics.newQuad(value[1], value[2], value[3], value[4], texture) --fs:loadImage(player.path)
		end
	end
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
end

--- Client loading routine at the start of program
function client.load()
	-- Set up initial values for client
    home.targetX = 0
    home.targetY = 0
    home.wantShoot = false
    home.move = { up = false, down = false, left = false, right = false }
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
function client.mousepressed(x, y, button)
    if button == 1 then
        home.wantShoot = true
		--client.send(string.format("click %s-%s", home.targetX, home.targetY))
    end

	if button == 2 then
		local home = client.home
		local share = client.share
		local diff_x = (client.width/2 - home.targetX)
		local diff_y = (client.height/2 - home.targetY)

		local pos_x = client.camera.x - diff_x
		local pos_y = client.camera.y - diff_y

		client.send(string.format("setpos %s %s %s", client.id, pos_x, pos_y))
	end
end

--- Callback for mouse button releasing on screen
---@param x number
---@param y number
---@param button number
function client.mousereleased(x, y, button)
    if button == 1 then
        home.wantShoot = false
    end
end

--- Callback for key press event
---@param k string Key pressed
function client.keypressed(k)
	client.key[k] = true
    if k == 'w' then home.move.up = true end
    if k == 's' then home.move.down = true end
    if k == 'a' then home.move.left = true end
    if k == 'd' then home.move.right = true end
end

--- Callback for key release event
---@param k string Key released
function client.keyreleased(k)
	client.key[k] = false
    if k == 'w' then home.move.up = false end
    if k == 's' then home.move.down = false end
    if k == 'a' then home.move.left = false end
    if k == 'd' then home.move.right = false end
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

client.actions = {
    -- Server only actions
	mapchange = {
		---Changes map currently being drawn on screen
		---@param ... string
		action = function(...)
			local args = {...}
			local status = client.map:read( "maps/"..table.concat(args," ")..".map" )
			if status then
				print(status)
			end
		end,
	};
    filecheck = {
		---Checks if a file exists on client side, and send a confirmation to server
		---@param ... string
        action = function(...)
            local args = {...}
            local path = table.concat(args," ")
            if fs:isFile(path) then
                print(string.format("file %s exists.", path))
            else
                print(string.format("file %s does not exist. Requesting", path))
            end
        end
    };
	scroll = {
		--- Scroll camera to a set position
		---@param x number
		---@param y number
		action = function(x,y)
    		x = tonumber(x) or 0
			y = tonumber(y) or 0

			client.camera.x = x
			client.camera.y = y
			client.map:scroll(x, y)
			print(string.format("scrolled to %s-%s", x, y))
		end
	};
	name = {
		---Changes name of this client
		---@param ... string
		action = function(...)
		end;
	};
}

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

	-- Interpolate the movement
	cache.x = b.lerp(cx, x, client.cache.tween_speed * dt)
	cache.y = b.lerp(cy, y, client.cache.tween_speed * dt)
end

--- Bullet movement updater
---@param bul table Bullet object
---@param dt number Delta time
function client.move_bullet(bul, dt)
    bul.x, bul.y = bul.x + 800 * bul.dirX * dt, bul.y + 800 * bul.dirY * dt
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
		--diff_x = 0
		--diff_y = 0
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

---Main game loop
---@param dt number
function client.update(dt)
	client.preupdate(dt)
	client.camera_move(dt)
	client.camera_tween(dt)

	if client.map then
		client.map:scroll(client.camera.x, client.camera.y)
		client.map:update(dt)
	end

    -- Do some client-side prediction
    if client.connected then
        -- Predictively move triangles
        for id, player in pairs(share.players) do
            -- We can use our `home` to apply controls predictively if it's our triangle
            ---client.move_player(player, dt, id == client.id and home or nil)
			client.move_player(id, player, dt)
        end

        -- Predictively move bullets
        for _, bul in pairs(share.bullets) do
            client.move_bullet(bul, dt)
        end
    end
	client.postupdate(dt)
end

---Main game render loop
function client.draw()
    love.graphics.push('all')
    -- Center and scale display
    local w, h = client.scale * client.width, client.scale * client.height
    local ox, oy = 0.5 * (love.graphics.getWidth() - w), 0.5 * (love.graphics.getHeight() - h)
    love.graphics.setScissor(ox, oy, w, h)
	--love.graphics.scale(client.scale)
	if client.map then
		client.map:draw_floor()
		client.map:draw_entities()
	end
    if client.connected then
	--if true then
        -- Player render
		--client.map:draw_players(share, home, client)
		client.map:draw_playersc(client)
		-- Bullet render
		client.map:draw_bullets(share, home, client)
		-- Draw items on the ground
		client.map:draw_items(share, client)
    end
	if client.map then
		client.map:draw_ceiling()
	end
	-- Resets scissoring
	love.graphics.pop()

	-- Draw the rest of hud
	local label = string.format("Camera: %dpx|%dpx  Ping: %s  FPS: %s  Target: %d|%d",
		client.camera.x,
		client.camera.y,
		client.getPing(),
		love.timer.getFPS(),
		home.targetX,
		home.targetY
	)
	love.graphics.printf(label, 0, love.graphics.getHeight()-20, love.graphics.getWidth(), "center")

	-- Draw middle screen
	love.graphics.line(love.graphics.getWidth()/2-5, love.graphics.getHeight()/2, love.graphics.getWidth()/2+5, love.graphics.getHeight()/2)
	love.graphics.line(love.graphics.getWidth()/2, love.graphics.getHeight()/2-5, love.graphics.getWidth()/2, love.graphics.getHeight()/2+5)
end

--- Returns the client object to the main code block
return client