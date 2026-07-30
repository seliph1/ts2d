local timerex = require("timerex")
local serpent = require("serpent")

-- Main table
local standard = {}

-- Constants
local TEAM_T = 1
local TEAM_CT = 2
local DEFAULT_SPEED = 5

-- States
local STATE_WAITING = 0
local STATE_FREEZE = 1
local STATE_RUNNING = 2
local STATE_ENDING = 3

-- Configuration
local FREEZE_TIME = 2
local BUY_TIME = 10
local MINIMUM_PLAYERS = 0
local FRIENDLY_FIRE = false

-- State Variables
local currentState = STATE_WAITING
local ct_spawn = {}
local t_spawn = {}

-- Dynamic zones
local buyzones = game("buyzones")


-- Helpers
local function freeze(uid)
	if uid then
		parse(string.format("speedmod %d %d", uid, 0))
		return
	end

	player(0, "apply", function(uid)
		parse(string.format("speedmod %d %d", uid, 0))
	end)
end

local function unfreeze(uid)
	if uid then
		parse(string.format("speedmod %d %d", uid, DEFAULT_SPEED))
		return
	end

	player(0, "apply", function(uid)
		parse(string.format("speedmod %d %d", uid, DEFAULT_SPEED))
	end)
end

local function getSpawnPointForPlayer(peer_id)
	-- Expecting to only have two teams (Terrorist and Counter-Terrorist)
	local team = player(peer_id, "team")
	local spawnpoints
	if team == TEAM_T then
		spawnpoints = t_spawn
	elseif team == TEAM_CT then
		spawnpoints = ct_spawn
	end

	if #spawnpoints == 0 then
		-- Just get a random valid position on the map
		local spawnpoint = {
			x = math.floor(map("xsize") / 2),
			y = math.floor(map("ysize") / 2)
		}
		local count = 0
		while count < 100 do -- avoiding infinite loops lmao
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
	return spawnpoints[math.random(#spawnpoints)]
end

local function balance_teams()
	local ct = player(0, "table", 2)
	local t = player(0, "table", 1)
	local ct_count = #ct
	local t_count = #t
	local diff = ct_count - t_count
	if diff > 1 then
		-- Move players from CT to T
		for i = 1, diff do
			local peer_id = ct[i]
			parse(string.format("setteam %d 1", peer_id))
		end
	elseif diff < -1 then
		-- Move players from T to CT
		for i = 1, math.abs(diff) do
			local peer_id = t[i]
			parse(string.format("setteam %d 2", peer_id))
		end
	end
end

function standard.second()
	local timeleft = game("timeleft")
	local timepassed = game("timepassed")
	local player_count = player(0, "count")

	if currentState == STATE_WAITING then
		-- void
	else
		if timepassed < FREEZE_TIME then
			currentState = STATE_FREEZE
		else
			currentState = STATE_RUNNING
		end
	end

	if timeleft <= 0 then
		parse("endround 0")
		currentState = STATE_ENDING
	end


	if player_count > 0 then
		local everyone_dead = true
		player(0, "apply", function(uid)
			if player(uid, "team") == 0 then
				everyone_dead = false
				return
			end

			if player(uid, "health") > 0 then
				everyone_dead = false
			end
		end)

		if everyone_dead then
			parse("endround 0")
		end
	end
end

function standard.init()
	local ct_spawn_entities = entitylist(0)
	local t_spawn_entities = entitylist(1)
	ct_spawn = {}
	t_spawn = {}

	for _, entity in pairs(ct_spawn_entities) do
		table.insert(ct_spawn, { x = entity.x, y = entity.y })
	end

	for _, entity in pairs(t_spawn_entities) do
		table.insert(t_spawn, { x = entity.x, y = entity.y })
	end
end

function standard.respawnrequest(peer_id)
	if currentState == STATE_WAITING or currentState == STATE_FREEZE then
		-- If on warmup rounds, or at the beggining on
		-- freezing time, let player spawn freely
		local spawnpoint = getSpawnPointForPlayer(peer_id)
		-- Get spawn point in pixel coordinates
		local spawn_x = spawnpoint.x * 32 + 16
		local spawn_y = spawnpoint.y * 32 + 16
		parse(string.format("spawnplayer %d %d %d", peer_id, spawn_x, spawn_y))
	end
end

function standard.startround_prespawn()
	print("Round start!")
	local freeze_timer = timerex(FREEZE_TIME * 1000, 1, unfreeze)
	if player(0, "count") >= MINIMUM_PLAYERS then
		currentState = STATE_FREEZE
	else
		currentState = STATE_WAITING
	end

	player(0, "apply", function(peer_id)
		if player(peer_id, "team") > 0 then
			local spawnpoint = getSpawnPointForPlayer(peer_id)
			local spawn_x = spawnpoint.x * 32 + 16
			local spawn_y = spawnpoint.y * 32 + 16
			parse(
				string.format(
					"spawnplayer_silent %d %d %d",
					peer_id,
					spawn_x,
					spawn_y
				)
			)
		end
	end)
end

function standard.spawn(peer_id)
	-- Spawn with a knife and a team item (glock or USP)
	-- 50 = Knife
	-- 1 = USP
	-- 2 = Glock

	local team = player(peer_id, "team")
	local items = { "50" }
	if team == TEAM_T then
		table.insert(items, "2")
	elseif team == TEAM_CT then
		table.insert(items, "1")
	end

	if currentState == STATE_WAITING then
		unfreeze(peer_id)
	elseif currentState == STATE_FREEZE then
		freeze(peer_id)
	elseif currentState == STATE_RUNNING then
		unfreeze(peer_id)
	end

	return table.concat(items, ",")
end

function standard.join(peer_id)
	local count = player(0, "count")
	if count > 2 then
		parse("endround 0")
	end

	if currentState == STATE_WAITING then
		msg2(peer_id, "©255220000Welcome to the server! We are currently in warmup round.")
	elseif currentState == STATE_FREEZE then
		local freeze_timer = FREEZE_TIME - game("timepassed")
		msg2(peer_id, "©255220000Welcome to the server! The game will start in " .. freeze_timer .. " seconds.")
	elseif currentState == STATE_RUNNING then
		msg2(peer_id, "©255220000Welcome to the server! The game is currently running.")
		msg2(peer_id, "©255220000Wait for the next round to play.")
	end
end

function standard.buy(uid, ...)
	local items = { ... }

	-- Check if player is in buyzone
	local x, y = player(uid, "tilepos")
	print("[", x, y, "]")
	if buyzones[x] and buyzones[x][y] then
		print("Player is in buyzone")
		return 0
	else
		print("Player is NOT in buyzone")
		return 1
	end
end

function standard.hit(victim_id, attacker_id, item_type, hpdamage, apdamage, rawdamage, object_id)
	--print(victim_id, attacker_id, item_type, hpdamage, apdamage, rawdamage, object_id)

	local victim_team = player(victim_id, "team")
	local attacker_team = player(attacker_id, "team")
	print(victim_team, attacker_team)
	if victim_team == attacker_team then
		if FRIENDLY_FIRE then
			return 0
		else
			return 1
		end
	end
end

return standard
