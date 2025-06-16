local cs = require "lib/cs"
local server = cs.server

local W, H = 800, 600 -- Game world size

server.enabled = true

local share = server.share
local homes = server.homes

function server.load()
    share.scores = {}
    share.players = {}
    share.bullets = {}
end

function server.connect(clientId)
    share.scores[clientId] = 0
    share.players[clientId] = {
        x = math.random(0, W),
        y = math.random(0, H),
        r = math.random(),
        g = math.random(),
        b = math.random(),
        vx = 0,
        vy = 0,
        targetX = 0,
        targetY = 0,
        shootTimer = 0, -- Can shoot if <= 0
        health = 100,
    }
end

function server.receive(id, ...)
	local args = {...}
	for k,v in pairs(args) do
		print(k,v)
	end
end

function server.disconnect(clientId)
    share.scores[clientId] = nil
    share.players[clientId] = nil
end

function server.setpos(clientId, x, y)
	if not server.clientExists(clientId) then return end
	share.players[clientId].x = x
	share.players[clientId].y = y
	server.log(1,"server",string.format("moved player to [%s-%s]",x,y))
end

function server.move_player(player, dt, home) -- `home` is used to apply controls if given
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

function server.move_bullet(bul, dt)
    bul.x, bul.y = bul.x + 800 * bul.dirX * dt, bul.y + 800 * bul.dirY * dt
end


local nextBulletId = 1 -- For choosing bullet ids

function server.update(dt)
	server.preupdate(dt)

    -- Triangles
    for clientId, player in pairs(share.players) do
        local home = homes[clientId]
        if home.move then -- Info may have not arrived yet
            -- Moving
            server.move_player(player, dt, home)

            -- Targeting
            player.targetX, player.targetY = home.targetX, home.targetY

            -- Shooting
            if player.shootTimer > 0 then -- Tick the shoot timer
                player.shootTimer = player.shootTimer - dt
            end
            if player.shootTimer <= 0 and home.wantShoot then -- Can and want to shoot? Shoot!
                local dirX, dirY = player.targetX - player.x, player.targetY - player.y
                if dirX == 0 and dirY == 0 then dirX = 1 end -- Prevent division by zero
                local dirLen = math.sqrt(dirX * dirX + dirY * dirY)
                dirX, dirY = dirX / dirLen, dirY / dirLen
                share.bullets[nextBulletId] = { -- Create the bullet
                    ownerClientId = clientId,
                    x = player.x + 30 * dirX,
                    y = player.y + 30 * dirY,
                    dirX = dirX,
                    dirY = dirY,
                    r = 1.5 * player.r,
                    g = 1.5 * player.g,
                    b = 1.5 * player.b,
                    lifetime = 1,
                }
                nextBulletId = nextBulletId + 1
                player.shootTimer = 0.2
                server.send('all', 'bulletSound')
            end

            -- Check if we got shot...
            local nang = -math.atan2(player.targetY - player.y, player.targetX - player.x)
            local sin, cos = math.sin(nang), math.cos(nang)
            for bulId, bul in pairs(share.bullets) do
                if bul.ownerClientId ~= clientId then -- Don't get shot by own bullet...
                    local dx, dy = bul.x - player.x, bul.y - player.y
                    local hitX, hitY
                    if dx * dx + dy * dy < 3600 then -- Ignore if far
                        for i = -1, 1, 0.2 do -- Check a few points to prevent 'tunneling'
                            -- Isosceles triangle point membership math...
                            local bx, by = bul.x + 18 * i * bul.dirX, bul.y + 18 * i * bul.dirY
                            local dx, dy = bx - player.x, by - player.y
                            local rdx, rdy = dx * cos - dy * sin, dx * sin + dy * cos
                            if rdx > -20 then
                                rdx = rdx + 20
                                rdy = math.abs(rdy)
                                if rdx / 50 + rdy / 20 < 1 then
                                    hitX, hitY = bx, by
                                    break
                                end
                            end
                        end
                    end
                    if hitX then -- We got shot!
                        share.bullets[bulId] = nil
                        player.health = player.health - 5
                        if player.health <= 0 then -- We died!
                            player.health = 100
                            player.x, player.y = math.random(10, W - 10), math.random(10, H - 10)
                            local shooterScore = share.scores[bul.ownerClientId] -- Award shooter
                            if shooterScore then
                                share.scores[bul.ownerClientId] = shooterScore + 1
                            end
                            server.send('all', 'bigExplosionSound')
                        else -- Just got hurt
                            server.send('all', 'smallExplosionSound')
                        end
                    end
                end
            end
        end
    end

    -- Bullets
    for bulId, bul in pairs(share.bullets) do
        server.move_bullet(bul, dt)
        bul.lifetime = bul.lifetime - dt
        if bul.lifetime <= 0 then
            share.bullets[bulId] = nil
        end
    end
	
	server.postupdate(dt)
end



return server
