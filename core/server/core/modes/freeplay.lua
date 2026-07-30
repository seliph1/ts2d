-- Freeplay / Map Testing Gamemode
-- Designed for testing maps without timers, freeze times, buy restrictions, or round limits.

local freeplay = {}

-- Constants
local DEFAULT_SPEED = 5

-- State Variables
local spawns = {}

local function unfreeze(uid)
	if uid then
		parse(string.format("speedmod %d %d", uid, DEFAULT_SPEED))
		return
	end

	player(0, "apply", function(uid)
		parse(string.format("speedmod %d %d", uid, DEFAULT_SPEED))
	end)
end

local function getSpawnPoint(peer_id)
	if #spawns > 0 then
		return spawns[math.random(#spawns)]
	end

	-- Fallback: find a random walkable tile on the map if no spawn entities exist
	local spawnpoint = {
		x = math.floor(map("xsize") / 2),
		y = math.floor(map("ysize") / 2)
	}
	local count = 0
	while count < 100 do
		local px = math.random(0, map("xsize"))
		local py = math.random(0, map("ysize"))
		if tile(px, py, "walkable") then
			spawnpoint.x = px
			spawnpoint.y = py
			break
		end
		count = count + 1
	end
	return spawnpoint
end

function freeplay.init()
	spawns = {}
	-- Collect all spawn points (T, CT, FFA, etc.)
	for entity_type = 0, 10 do
		local entities = entitylist(entity_type)
		if entities then
			for _, entity in pairs(entities) do
				if entity.x and entity.y then
					table.insert(spawns, { x = entity.x, y = entity.y })
				end
			end
		end
	end
end

function freeplay.startround_prespawn()
	print("[Freeplay] Map testing session active - No timers or round limits.")
	player(0, "apply", function(peer_id)
		if player(peer_id, "team") >= 0 then
			local spawnpoint = getSpawnPoint(peer_id)
			local spawn_x = spawnpoint.x * 32 + 16
			local spawn_y = spawnpoint.y * 32 + 16
			parse(string.format("spawnplayer_silent %d %d %d", peer_id, spawn_x, spawn_y))
		end
	end)
end

function freeplay.spawn(peer_id)
	unfreeze(peer_id)
	-- Give starter weapons (Knife 50, USP 1, Glock 2, AK47 30, M4A1 32)
	return "50,1,2,30,32"
end

function freeplay.respawnrequest(peer_id)
	-- Instant respawn on request
	local spawnpoint = getSpawnPoint(peer_id)
	local spawn_x = spawnpoint.x * 32 + 16
	local spawn_y = spawnpoint.y * 32 + 16
	parse(string.format("spawnplayer %d %d %d", peer_id, spawn_x, spawn_y))
end

function freeplay.second()
	-- No time limit, no freeze time, no round ending timers!
end

function freeplay.join(peer_id)
	msg2(peer_id, "©000255000Welcome! Server running Freeplay / Map Testing Mode.")
	msg2(peer_id, "©000255000No round timers, unlimited buying, instant respawns.")
end

function freeplay.buy(uid, ...)
	-- Allow buying anywhere, anytime in freeplay mode
	return 0
end

function freeplay.hit(victim_id, attacker_id, item_type, hpdamage, apdamage, rawdamage, object_id)
	-- Basic combat: allow damage
	return 0
end

function freeplay.die(victim_id, attacker_id)
	msg2(victim_id, "©255150000You died. Request respawn anytime to continue testing!")
end

return freeplay
