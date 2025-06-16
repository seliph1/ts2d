local cs = require "lib/cs"
local MapObject = require "mapengine"

local bulletSound = love.audio.newSource('assets/laser.wav', 'static')
local smallExplosionSound = love.audio.newSource('assets/hurt.wav', 'static')
local bigExplosionSound = love.audio.newSource('assets/explosion.wav', 'static')

local client = cs.client
local share = client.share
local home = client.home

client.enabled = true
client.map = MapObject.new(50, 50)
client.camera = {
	x = 0,
	y = 0,
}
client.key = {}


--[[
local function normalize(x,y,w,h)
	return (x/w)*2 - 1, (w/h)*2 - 1
end--]]

local W, H = 800, 600 -- Game world size
local DISPLAY_SCALE = 1 -- Scale to draw graphics at w.r.t game world units

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

function client.load()
    -- Use `home` to store control info so the server can see it
    home.targetX = 0
    home.targetY = 0
    home.wantShoot = false
    home.move = { up = false, down = false, left = false, right = false }
end

function client.mousemoved(x, y)
    -- Transform mouse coordinates according to display centering and scaling (see `.draw` below)
    --local w, h = DISPLAY_SCALE * W, DISPLAY_SCALE * H
    --local ox, oy = 0.5 * (love.graphics.getWidth() - w), 0.5 * (love.graphics.getHeight() - h)
    --home.targetX, home.targetY = (x - ox) / DISPLAY_SCALE, (y - oy) / DISPLAY_SCALE
	--print(home.targetX, home.targetY)
	
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	home.targetX = math.floor((x/w)*W)
	home.targetY = math.floor((y/h)*H)
end

function client.mousepressed(x, y, button)
    if button == 1 then
        home.wantShoot = true
		
		client.send(string.format("click %s-%s",home.targetX, home.targetY))
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
	
	
	if k == "'" then
		if console_frame then
			console_frame:ToggleVisibility()
		end
	end
end

function client.keyreleased(k)
	client.key[k] = false
	
    if k == 'w' then home.move.up = false end
    if k == 's' then home.move.down = false end
    if k == 'a' then home.move.left = false end
    if k == 'd' then home.move.right = false end
end

function client.receive(message)
    if message == 'bulletSound' then
        bulletSound:setPitch(1.4 + 0.3 * math.random())
        bulletSound:stop()
        bulletSound:play()
    elseif message == 'smallExplosionSound' then
        smallExplosionSound:setPitch(1.4 + 0.3 * math.random())
        smallExplosionSound:stop()
        smallExplosionSound:play()
    elseif message == 'bigExplosionSound' then
        bigExplosionSound:setPitch(0.7 + 0.3 * math.random())
        bigExplosionSound:stop()
        bigExplosionSound:play()
    end
	
	--print("received message: "..message)
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


function client.draw()
    love.graphics.push('all')

    -- Center and scale display
    local w, h = DISPLAY_SCALE * W, DISPLAY_SCALE * H
    local ox, oy = 0.5 * (love.graphics.getWidth() - w), 0.5 * (love.graphics.getHeight() - h)
    love.graphics.setScissor(ox, oy, w, h)
	--love.graphics.scale(DISPLAY_SCALE)

	if client.map then
		client.map:draw_floor()
		
		--client.map:draw_entities()
	end

    if client.connected then
        -- Player render
		client.map:draw_players(share, home, client)
		
		-- Bullet render
		client.map:draw_bullets(share, home, client)
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
        for bulId, bul in pairs(share.bullets) do
            client.move_bullet(bul, dt)
        end
    end

    -- Scale down display if window is too small
    --local w, h = love.graphics.getDimensions()
    --DISPLAY_SCALE = math.min(1, w / W, h / H)
	
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


-- Render map engine 2.0




return client
