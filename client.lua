local cs 		= require "lib/cs"
local MapObject = require "mapengine"
local enum      = require "enum"

require "lib/lovefs/lovefs"

local fs = lovefs()
if love.filesystem.isFused() then
	fs:cd(love.filesystem.getSourceBaseDirectory() )
else
	fs:cd(love.filesystem.getSource() )
end

--- Client base framework
local client = cs.client

--- Table that gets info from server
local share = client.share

--- Use `home` to store control info so the server can see it
--- @class userdata home
--- @field targetX integer position of our client
--- @field targetY integer position of our client
--- @field wantShoot boolean variable that stores our mouse keypresses
--- @field move table direction vector
local home = client.home

client.enabled = true
client.map = MapObject.new(50, 50)
--client.map:read("maps/as_snow.map")
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
}
client.key = {}
client.gfx = {
	itemlist = {};
	hud = {};
	objects = {};
	player = {};
}

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

function client.camera_move(dt)
	local s = 500*dt
	if client.key.space then
		s = 500*dt*5
	end

	if (client.key.up) then
		client.camera.y = client.camera.y - s
	end
	if (client.key.left) then
		client.camera.x = client.camera.x - s
	end
	if (client.key.down) then
		client.camera.y = client.camera.y + s
	end
	if (client.key.right) then
		client.camera.x = client.camera.x + s
	end
end

function client.changed(payload)
	for category, data in pairs(payload) do
		if category == "items" then
			--client.map:update_items(22)
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

function client.load()
    home.targetX = 0
    home.targetY = 0
    home.wantShoot = false
    home.move = { up = false, down = false, left = false, right = false }
end

function client.mousemoved(x, y)
    -- Transform mouse coordinates according to display centering and scaling
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	home.targetX = math.floor((x/w)*client.width)
	home.targetY = math.floor((y/h)*client.height)
end

function client.mousepressed(x, y, button)
    if button == 1 then
        home.wantShoot = true
		--client.send(string.format("click %s-%s",home.targetX, home.targetY))
    end
end

function client.mousereleased(x, y, button)
    if button == 1 then
        home.wantShoot = false
    end
end

function client.keypressed(k)
	client.key[k] = true
    if k == 'w' then home.move.up = true end
    if k == 's' then home.move.down = true end
    if k == 'a' then home.move.left = true end
    if k == 'd' then home.move.right = true end
end

function client.keyreleased(k)
	client.key[k] = false
    if k == 'w' then home.move.up = false end
    if k == 's' then home.move.down = false end
    if k == 'a' then home.move.left = false end
    if k == 'd' then home.move.right = false end
end


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
	["mapchange"] = {
		action = function(...)
			local args = {...}
			local status = client.map:read( "maps/"..table.concat(args," ")..".map" )
			if status then
				print(status)
			end
		end,
	};
    ["filecheck"] = {
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
	["scroll"] = {
		action = function(x,y)
    		x = tonumber(x) or 0
			y = tonumber(y) or 0

			client.camera.x = x
			client.camera.y = y
			client.map:scroll(x, y)
			print(string.format("scrolled to %s-%s", x, y))
		end
	};
	["name"] = {
		action = function(name)
		end;
	};
}

function client.receive(message)
    client.parse(message)
end

function client.move_player(player, dt, home) -- `home` is used to apply controls if given
    player.vx, player.vy = 0, 0
    if home then
        local move = home.move
        if move.up then player.vy = player.vy - 220 end
        if move.down then player.vy = player.vy + 220 end
        if move.left then player.vx = player.vx - 220 end
        if move.right then player.vx = player.vx + 220 end
    end
    local v = math.sqrt(player.vx * player.vx + player.vy * player.vy)
    if v > 0 then player.vx, player.vy = 220 * player.vx / v, 220 * player.vy / v end -- Limit speed
    player.x, player.y = player.x + player.vx * dt, player.y + player.vy * dt
    player.x, player.y = math.max(0, math.min(player.x, 20000)), math.max(0, math.min(player.y, 20000))
end

function client.move_bullet(bul, dt)
    bul.x, bul.y = bul.x + 800 * bul.dirX * dt, bul.y + 800 * bul.dirY * dt
end
--//-------------------------------------------------------------
-- Fake share table 
--//-------------------------------------------------------------
--[[
---@param tbl table
---@return number
function Rift(tbl) -- (R)andom (I)ndex (F)rom (T)able)
	local tk = {}
	for k, v in pairs(tbl) do
		tk[#tk+1] = k
	end
	return tk[ math.random(1, #tk) ]
end

local fake_share = {
	players = {
		[1] = {
			x = 32*4,
			y = 32*4,
			vx = 0,
			vy = 0,
			targetX = 0,
			targetY = 0,
			shootTimer = 0, -- Can shoot if <= 0
			health = 100,
			p = "ct1",
			h = 30 -- holding
		};
	};
	items = {
		[1] = {
			id = 30,
			ac = 0,
			am = 0,
			x = 5,
			y = 5,
			r = math.random(0, 360),
		};
	};
	bullets = {};
}

test = {}
test["10|10"] = {}

for i=1,100000 do
	table.insert(fake_share.items, {
		id = Rift(client.content.itemlist),
		--id = 30,
		ac = 0,
		am = 0,
		x = 5,--math.random(1, 500),
		y = 5,--math.random(1, 500),
		r = math.random(0, 360),
	})
end
]]

function client.draw()
    love.graphics.push('all')
    -- Center and scale display
    local w, h = client.scale * client.width, client.scale * client.height
    local ox, oy = 0.5 * (love.graphics.getWidth() - w), 0.5 * (love.graphics.getHeight() - h)
    love.graphics.setScissor(ox, oy, w, h)
	--love.graphics.scale(client.scale)
	if client.map then
		client.map:draw_floor()
		--client.map:draw_entities()
	end
    if client.connected then
	--if true then
        -- Player render
		client.map:draw_players(share, home, client)
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
	local label = string.format("Camera: %dpx|%dpx  Ping: %s  FPS: %s", 
		client.camera.x,
		client.camera.y,
		client.getPing(),
		love.timer.getFPS()
	)
	love.graphics.printf(label, 0, love.graphics.getHeight()-20, love.graphics.getWidth(), "center")
end

function client.update(dt)
	client.preupdate(dt)
	client.camera_move(dt)
	if client.map then
		client.map:scroll(client.camera.x, client.camera.y)
		client.map:update(dt)
	end
    -- Do some client-side prediction
    if client.connected then
        -- Predictively move triangles
        for id, player in pairs(share.players) do
            -- We can use our `home` to apply controls predictively if it's our triangle
            client.move_player(player, dt, id == client.id and home or nil)
        end

        -- Predictively move bullets
        for _, bul in pairs(share.bullets) do
            client.move_bullet(bul, dt)
        end
    end

	client.postupdate(dt)
end

-- Quick hack to try local overrides for player input -- will test this more
--function client.changing(diff)
--    if diff.triangles then
--        local myTri = diff.triangles[client.id]
--        if myTri then
--            if myTri.x and share.triangles[client.id].x then
--                myTri.x = 0.98 * share.triangles[client.id].x + 0.02 * myTri.x
--            end
--            if myTri.y and share.triangles[client.id].y then
--                myTri.y = 0.98 * share.triangles[client.id].y + 0.02 * myTri.y
--            end
--        end
--    end
--end
return client
