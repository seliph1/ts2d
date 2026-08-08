local MapObject      = require "mapengine"
local cs             = require "lib.cs"
local bump           = require "lib.bump"
local battery        = require "lib.battery"
local serpent        = require "lib.serpent"
local mlib           = require "lib.mlib"
local enum           = require "core.enum"

local server         = cs.server

local max            = math.max
local min            = math.min
local sqrt           = math.sqrt
local atan2          = math.atan2
local random         = math.random
local floor          = math.floor
local ceil           = math.ceil
local cos            = math.cos
local sin            = math.sin
local abs            = math.abs
local rad            = math.rad

server.enabled       = true
server.content       = enum

server.world         = bump.newWorld()
server.width         = 800
server.height        = 600
server.sendRate      = 30
server.version       = "v1.0.1"
server.actions       = require "actions" (server)
server.hooks         = {}
server.timers        = {}
server.endround_flag = false

for index, hook in pairs(server.content.HOOK_LIST) do
	server.hooks[hook] = {}
end

for action, data in pairs(server.actions) do
	if data.alias then
		for index, alias in pairs(data.alias) do
			server.actions[alias] = data
		end
	end
end
---@class Share: state
local share = server.share

---@class Homes: table
local homes = server.homes

function server.load(map_name)
	-- Welcome message
	print("******** C4 Dedicated Server ********")
	-- Load and start the netcode
	server.start("*", "36963")

	-- Load map
	server.map = MapObject.new() -- 50x50 tile map
	local default_map = "maps/de_dust.map"
	local target_map = default_map

	if type(map_name) == "string" and map_name ~= "" then
		if not map_name:find("^maps/") then
			target_map = "maps/" .. map_name
		else
			target_map = map_name
		end
	end

	local ok, err = pcall(function() server.map:read(target_map, true) end)
	if not ok then
		print("Failed to load map: " ..
			tostring(target_map) .. " (" .. tostring(err) .. "), falling back to default map.")
		server.map:read(default_map, true)
	end

	server.log(1, "game", tostring(server.map))

	server.spawnpoints = server.map:getSpawnPoints()
	server.files       = server.map:getFiles()

	-- Fill the world table data
	share.items        = {}
	share.players      = {}
	share.bullets      = {}
	share.objects      = {}
	share.entities     = {}

	-- Add the entity state to the sync table
	local entities     = server.map:getEntities()
	for _, e in ipairs(entities) do
		if e.state then
			share.entities[e.index] = {
				state = e.state
			}
		end
	end
	share.config       = {
		--//-----------------------------------------------------------------//--
		--// SHOP CONFIG                                                     //
		--//-----------------------------------------------------------------//--
		shop = {
			-- Gamemode 0: Standard
			{
				name = "Handgun",
				icon = "weapons/deagle_d.bmp",
				items = {
					1, 2, 3, 4, 5, 6
				},
				teamitems = {
					[1] = 2,
					[2] = 1,
				},
			},
			{
				name = "Shotgun",
				icon = "weapons/m3_d.bmp",
				items = {
					10, 11
				},
			},
			{
				name = "Sub Machine Gun",
				icon = "weapons/p90_d.bmp",
				items = {
					20, 21, 22, 23, 24
				},
				teamitems = { -- item_id -> team_id
					[21] = 1,
					[23] = 2,
				},
			},
			{
				name = "Rifle",
				icon = "weapons/ak47_d.bmp",
				items = {
					30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 91
				},
				teamitems = {
					[30] = 1,
					[31] = 1,
					[32] = 2,
					[33] = 2,
				},
			},
			{
				name = "Machine Gun",
				icon = "weapons/m249_d.bmp",
				items = {
					40
				},
			},
			0,
			{
				name = "Primary Ammo",
				icon = "weapons/primaryammo.bmp",
				items = 61,
			},
			{
				name = "Secondary Ammo",
				icon = "weapons/secondaryammo.bmp",
				items = 62,
			},
			{
				name = "Equipment",
				icon = "weapons/kevlar+helm_d.bmp",
				items = {
					41, 56, 57, 58, 59, -- Equips
					51, 52, 53, 54, -- Grenades
				},
				teamitems = {
					[41] = 2,
					[56] = 2,
				},
			},

			price_override = {
				[1] = 10,
			}
		},
		--//-------------------//--
		--// TEAM CONFIG       //
		--//-------------------//--
		teams = {
			-- Gamemode 0: Standard
			[0] = {
				name       = "Spectator",
				color      = "128128128",
				faction_id = 0,
			},
			[1] = {
				name = "Terrorist",
				color = "254025000",
				faction_id = 1,
				looks = {
					{ name = "Phoenix Connexion", appearance = "t1.bmp" },
					{ name = "Elite Crew",        appearance = "t2.bmp" },
					{ name = "Arctic Avengers",   appearance = "t3.bmp" },
					{ name = "Guerilla Warfare",  appearance = "t4.bmp" },
				}
			},
			[2] = {
				name = "Counter-Terrorist",
				color = "050150254",
				faction_id = 2,
				looks = {
					{ name = "Seam Teal 6", appearance = "ct1.bmp" },
					{ name = "GSG9",        appearance = "ct2.bmp" },
					{ name = "SAS",         appearance = "ct3.bmp" },
					{ name = "GIGN",        appearance = "ct4.bmp" },
				}
			},
		},

	}
	share.scores       = {}
	share.playerscores = {}
	share.game         = {
		-- Values here expressed in seconds
		timer = 3000,
		timer_start = os.time(),
		bombtime = 20,
		buytime = 10,
		round = 1,
		paused = false,
		pause_start = 0,
		phase = 0,
	}

	-- Load the environment
	server.env         = require "env" (server)
	-- Start the first round
	server.startround()
end

local function is_alive(peer_id)
	local player = share.players[peer_id]
	if player then
		return player.h > 0
	end
end

local function is_dead(peer_id)
	local player = share.players[peer_id]
	if player then
		return player.h <= 0
	end
end

function server.connect(peer_id)
	server.callhook("connect", peer_id)
end

function server.identity(peer_id, name)
	local peer = server.getENetPeer(peer_id)
	local peer_string = tostring(peer)
	local ip, port = string.match(peer_string, "([^:]+):(%d+)")
	local usgnID = ""
	local usgnname = ""
	local steamID = ""
	local steamname = ""
	server.callhook("connect_attempt", name, ip, port, usgnID, usgnname, steamID, steamname)
end

function server.prejoin(peer_id)
	server.send(peer_id, string.format("mapchange %s", server.map:name()))

	local client_name = server.getClientName(peer_id)
	local player = server.new_player(client_name)

	-- Burn player id inside object for self-refence and redundancy
	player.id = peer_id
	share.players[peer_id] = player
	share.playerscores[peer_id] = {
		s = 0,
		d = 0,
		a = 0,
		hk = 0,
		tk = 0,
		tbk = 0,
		mvp = 0,
	}
	server.world:add(share.players[peer_id], 0, 0, player.size, player.size)

	server.callhook("connect_initplayer", peer_id)
	server.callhook("connect", peer_id)
end

function server.join(peer_id)
	server.callhook("join", peer_id)

	server.send(peer_id, "menu_team")
end

function server.disconnect(peer_id)
	server.callhook("leave", peer_id)

	local home = homes[peer_id]
	local player = share.players[peer_id]
	local announcement
	if player then
		if server.world:hasItem(player) then
			server.world:remove(player)
		end
		announcement = string.format("%s disconnected.", player.n)
	end

	share.playerscores[peer_id] = nil
	share.players[peer_id] = nil
	if announcement then
		server.log(1, "server", announcement)
	end
	local reason = "?"

	server.callhook("disconnect", peer_id, reason)
end

function server.receive(id, ...)
	local args = { ... }
	for k, v in pairs(args) do
		server.parse(id, v)
	end
end

function server.message(peer_id, ...)
	local message = ""
	for i = 1, select("#", ...) do
		message = message .. " " .. tostring(select(i, ...))
	end
	server.send(peer_id, string.format("msg %s", message))
end

function server.parse(peer_id, str)
	server.callhook("parse", str)
	local args = {}
	assert(type(str) == "string")
	assert(type(peer_id) == "number")
	for word in string.gmatch(str, "%S+") do
		table.insert(args, word)
	end

	local action_id = args[1]
	local actions = server.actions
	if not actions then return end
	if actions[action_id] then
		local action_object = actions[action_id]
		local source = action_object.source or "remote"
		if source == "local" and peer_id ~= 0 then
			server.log(1, "parse", string.format("Action [%s] can only be executed by the server!", str))
			return
		end

		if action_object.action then
			local f = action_object.action
			local status, action_status = pcall(f, action_id, tonumber(peer_id), unpack(args, 2))
			if not status then
				server.log(7, "error", action_status)
				return
			end
			if action_status then
				server.log(1, "parse", string.format("%s: %s", action_id, status))
			end
		end
	else
		server.log(1, "parse", string.format("Unknown action: [%s] | Origin: [Player ID: %s]", str, peer_id))
	end
end

function server.changing(peer_id, payload)
end

function server.changed(peer_id, payload)
end

function server.new_player(name)
	-- Parameters with (_) prefix means it wont be shared across peers
	return {
		ct = 1,         -- collision type: 1 (player)
		ih = 0,         -- item held
		h = 0,          -- Health
		mh = 100,       -- Max health
		s = 5,          -- Speed
		t = 0,          -- Team
		n = name or "Player", -- Name
		p = "default.png", -- Appearance
		pi = 0,         -- Process ID
		pt = 0,         -- Process timer
		vk = 0,         -- Votekick player id
		vm = "",        -- Votemap name
		x = 0,          -- X Position
		y = 0,          -- Y Position
		i = {},         -- Items
		e = {},         -- Equipment
		a = 0,          -- Armor
		ah = 0,         -- Armor life
		m = 16000,      -- Money
		targetX = 0,    -- Mouse X Position
		targetY = 0,    -- Mouse Y Position
		size = 26,
		_reloadTimer = 0, -- Reload timer cooldown
		_attack1Timer = 0, -- Primary Attack timer cooldown
		_attack2Timer = 0, -- Secondary Attack timer cooldown
	}
end

function server.new_item(item_type, item_id, x, y)
	local itemdata = server.content.itemlist[item_type]
	local item_object = {
		ct = 2, -- collision type: 2(item)
		it = item_type,
		ac = itemdata.ammo_cap,
		am = itemdata.ammo_mag,
		m = 1,
		id = item_id,
		r = random(0, 360),
		x = x,
		y = y,
	}

	return item_object
end

function server.setmoney(peer_id, money)
	local player = share.players[peer_id]
	if not player then
		server.log(1, "error", "(setmoney) There is no player on the world with this ID")
		return false
	end
	player.m = money
	if player.m <= 0 then
		player.m = 0 -- No more money!
	end
end

function server.decreasemoney(peer_id, money)
	local player = share.players[peer_id]
	if not player then
		server.log(1, "error", "(decreasemoney) There is no player on the world with this ID")
		return false
	end
	if player.m >= money then
		player.m = player.m - money
		return true
	else
		return false
	end
end

function server.sethealth(peer_id, health)
	local player = share.players[peer_id]
	if not player then
		return false, server.log(1, "error", "(sethealth) There is no player on the world with this ID")
	end
	player.h = math.min(health, player.mh)
	if player.h <= 0 then
		player.h = 0

		server.die(peer_id, 0, 0)
	end
end

function server.decreasehealth(peer_id, decrease)
	local player = share.players[peer_id]
	if not player then
		return false, server.log(1, "error", "(decreasehealth) There is no player on the world with this ID")
	end
	player.h = math.max(player.h - decrease, 0)
	if player.h <= 0 then
		player.h = 0

		server.die(peer_id, 0, 0)
	end
end

function server.kill(attacker_id, victim_id, item_type)
	local victim = share.players[victim_id]
	local attacker = share.players[attacker_id]

	server.callhook("kill", attacker_id, victim_id, item_type, victim.x, victim.y)
	--server.send("all", string.format("kill %s %s %s", attacker_id, victim_id, item_type) )
end

function server.die(victim_id, attacker_id, item_type)
	local victim = share.players[victim_id]
	local attacker = share.players[attacker_id]

	server.callhook("die", victim_id, attacker_id, item_type, victim.x, victim.y)
	server.send("all", string.format("die %s %s %s %s %s", victim_id, attacker_id, item_type, victim.x, victim.y))
end

--[[Whenever the player with the given id is hit/damaged.
source is the ID of the player who attacked or who built the building which attacked/caused damage.
It can also be 0 in some cases:
    the environment/map/an entity caused damage
    an NPC caused damage
    a neutral building caused damage (e.g. turret or gate field)
    a building of a player who already left the game caused damage
    a projectile caused damage but the player left before the projectile reached its target/exploded

weapon can be a weapon type ID or a special source ID (see images below).
Often source will be 0 if the damage was caused by a special source.
In many cases you will then get the ID of the attacking object with the object parameter.

hpdmg is the value which will be subtracted from the victim's health and apdmg is the value which will be subtracted from its armor.
rawdmg is the actual raw damage which was caused by the attack without taking the armor of the victim into account.

CS2D Damage calculation (in this order):
    if a player is a zombie (zombie sv_gamemode only), damage will be reduced based on mp_zombiedmg
    if a player wears a special armor, damage will be reduced by the displayed percentage in the HUD (damage * (100-protection)/100)
    if a player wears kevlar armor (armor value between 1 and 200), health and armor are changed based on mp_kevlar (see mp_kevlar for details)
    if multiple players/things are hit by a single shot, mp_shotweakening can reduce the damage for the second, third etc. player who is hit

You can ignore the hit (the victim won't suffer any damage) by returning 1.
Note that on client side you will always hit effects (e.g. blood) even when returning 1.--]]
function server.hit(victim_id, attacker_id, item_type, damage, object_id)
	local victim = share.players[victim_id]
	local attacker = share.players[attacker_id]

	-- TODO: calculate armor damage mitigation
	-- TODO: implement armor health
	-- TODO: calculate curtailed damage based on distance
	-- For now all damage is treated as raw damage!
	local apdamage = 0
	local rawdamage = damage
	local hpdamage = damage

	-- HOOK order: hit > die
	local result = server.callhook("hit", victim_id, attacker_id, item_type, hpdamage, apdamage, rawdamage, object_id)
	-- Result = 0 means no cancel
	-- Result = 1 means cancel
	result = result or 0
	if result == 0 then
		-- Send hit action.
		-- I still dont know what to send to client. but for now it will be that:
		server.send("all", string.format("hit %s %s %s", victim_id, attacker_id, item_type))

		-- TODO: add the server.decreasearmor here.

		-- Damage if not cancelled and victim is alive
		if victim.h > 0 then
			server.decreasehealth(victim_id, hpdamage)
		end
	end
end

function server.menu(peer_id, str)
	server.send(peer_id, "menu " .. str)
end

function server.setcamera(peer_id, mode, ...)
	if mode == "self" then
		server.send(peer_id, "camera self")
	elseif mode == "follow" then
		local category = arg[1]
		local id = tonumber(arg[2]) or 0

		if not share[category] then return "(camera) There is no category with that name" end
		if not share[category][id] then return "(camera) There is no entity with this ID" end
		local object = share[category][id]
		if object and object.x and object.y then
			server.send(peer_id, string.format("camera follow %s %s", category, id))
		end
	elseif mode == "translate" then
		local x = tonumber(arg[1]) or 0
		local y = tonumber(arg[2]) or 0
		server.send(peer_id, string.format("camera translate %s %s", x, y))
	elseif mode == "unbind" then
		server.send(peer_id, "camera unbind")
	end
end

function server.effect(peer_id, effect_name, x, y, p1, p2, r, g, b)
	server.send(peer_id, string.format("effect %s %s %s %s %s %s %s %s", effect_name, x, y, p1, p2, r, g, b))
end

function server.positionPlayerOnSpawnPoint(peer_id)
	local spawnpoint = {}
	local collided = true
	while collided do
		local px = math.random(0, server.map:getWidth())
		local py = math.random(0, server.map:getHeight())
		if server.map:isCollidingWithTile(px, py) then
			collided = true
		else
			spawnpoint.x = px
			spawnpoint.y = py
			collided = false
		end
	end

	if #server.spawnpoints > 0 then
		spawnpoint = server.spawnpoints[random(1, #server.spawnpoints)]
	end
	local spawn_x = spawnpoint.x * 32 + 16
	local spawn_y = spawnpoint.y * 32 + 16
	server.setpos(peer_id, spawn_x, spawn_y)
end

function server.getSpawnPointForPlayer(peer_id)
	local player = share.players[peer_id]
	if not player then return 0, 0 end

	local spawnpoint = {
		x = math.floor(server.map:getWidth() / 2),
		y = math.floor(server.map:getHeight() / 2)
	}
	if #server.spawnpoints > 0 then
		spawnpoint = server.spawnpoints[random(1, #server.spawnpoints)]
	else
		local count = 0
		while count < 100 do -- avoiding infinite loops lmao
			local px = math.random(0, server.map:getWidth())
			local py = math.random(0, server.map:getHeight())
			if not server.map:isCollidingWithTile(px, py) then
				spawnpoint.x = px
				spawnpoint.y = py
				break
			end
			count = count + 1
		end
	end
	local spawn_x = spawnpoint.x * 32 + 16
	local spawn_y = spawnpoint.y * 32 + 16
	return spawn_x, spawn_y
end

---@param peer_id number
---@param x? number
---@param y? number
function server.spawnplayer(peer_id, x, y, silent)
	local player = share.players[peer_id]
	if not player then
		return false, server.log(1, "error", "(spawnplayer) There is no player on the world with this ID")
	end
	if not (x and y) or (x < 0 or y < 0) then
		x, y = server.getSpawnPointForPlayer(peer_id)
	end

	local spawn_item_string = server.callhook("spawn", peer_id, x, y)
	local spawn_items = {}
	if type(spawn_item_string) == "string" then
		for item_type in string.gmatch(spawn_item_string, "([^,]+)") do
			table.insert(spawn_items, item_type)
		end
	end
	if #spawn_items > 0 then
		server.equip(peer_id, unpack(spawn_items))
	end

	server.sethealth(peer_id, player.mh)
	server.setpos(peer_id, x, y)
	server.setcamera(peer_id, "self")

	-- Send the spawn effect to everyone
	if not silent then
		server.send("all", string.format("spawn %s %s %s", peer_id, x, y))
	end
end

function server.spawnplayer_silent(peer_id, x, y)
	server.spawnplayer(peer_id, x, y, true)
end

function server.select(player_id, item_type)
	local player = share.players[player_id]
	if not player then
		return server.log(1, "error", "(select) There is no player on the world with this ID")
	end
	if player.ih == item_type then return end
	if player.i[item_type] or item_type == 0 then
		player.ih = item_type
		server.reloadcancel(player_id)
		server.callhook("select", player_id, item_type)
	end
end

function server.spawnitem(item_type, x, y, tbl)
	-- object type (flat table)
	local itemdata = server.content.itemlist[item_type]
	if not itemdata then
		return
	end

	local item_id = #share.items + 1
	local item_object = server.new_item(item_type, item_id, x, y)

	if tbl then
		for k, v in pairs(tbl) do
			if item_object[k] then
				item_object[k] = v
			end
		end
	end

	share.items[item_id] = item_object
	server.world:add(share.items[item_id], x * 32, y * 32, 32, 32)

	--server.log(1, "game", string.format("spawned item [ID:%s type:%s] to T:[%s-%s]", item_id, item_type, x, y))
	return item_object
end

function server.removeitem(item_id)
	local item_object = share.items[item_id]
	if not item_object then
		return server.log(1, "error", "(removeitem) There is no item on the world with this ID")
	end

	local x, y = item_object.x, item_object.y
	server.world:remove(item_object)

	share.items[item_id] = nil

	--server.log(1, "game", string.format("Item ID %s [%s-%s] deleted!", item_id, x, y))
	return item_object
end

function server.buy(player_id, ...)
	-- TODO: Check if player is in a buy zone
	-- Left for gamemodes:
	local response = server.callhook("buy", player_id, ...)
	response = response or 0
	if response == 0 then  -- Allow
	elseif response == 1 then -- Block
		return
	end

	for index, item in pairs({ ... }) do
		local item_type = tonumber(item)
		if not item_type then
			-- Search for item of this name
			for index, itemdata in pairs(enum.itemlist) do
				if string.lower(itemdata.internal_name) == string.lower(item) then
					item_type = index
					break
				end
			end
		end


		local player = share.players[player_id]
		if not player then
			return server.log(1, "error", "(buy) There is no player on the world with ID [" .. tostring(player_id) .. "]")
		end

		if not server.content.itemlist[item_type] then
			return false, string.format("(buy) Item \"%s\" doesn't exist", item_type)
		end

		if item_type == 0 or item_type == nil then
			return false, "(buy) Item type missing"
		end

		local itemdata = server.get_item_data(item_type)
		local price = itemdata.price or 100
		if player.m < price then
			return false, "(buy) Not enough money"
		end

		-- Change weapon held to this item collected, if it is holdable.
		if itemdata.slot then --if heldable[itemdata.category] then
			-- If it's a thing we can wield on hands, collect it and remove from world.
			if not player.i[item_type] then
				local item_object = server.new_item(item_type)
				player.m = player.m - price
				player.i[item_type] = item_object
				server.select(player_id, item_type)
			end
		elseif itemdata.category == "armor" then
			if player.a == item_type then
				-- Nothing
			else
				player.m = player.m - price
				-- Set the new armor
				player.a = item_type
			end
		elseif itemdata.category == "equipment" then
			if player.e[item_type] then
				-- dont collect
			else
				player.m = player.m - price
				player.e[item_type] = true
			end
		end
	end -- for k,v in pairs({...}) do
end

-- Add item to player
function server.equip(player_id, ...)
	for _, item in pairs({ ... }) do
		local item_type = tonumber(item)
		if not item_type then
			-- Search for item of this name
			for index, itemdata in pairs(enum.itemlist) do
				if string.lower(itemdata.internal_name) == string.lower(item) then
					item_type = index
					break
				end
			end
		end


		local player = share.players[player_id]
		if not player then
			return server.log(1, "error", "(equip) There is no player on the world with this ID")
		end

		if not server.content.itemlist[item_type] then
			return false, string.format("(equip) Item \"%s\" doesn't exist", item_type)
		end

		if item_type == 0 or item_type == nil then
			return false, "(equip) Item type missing"
		end

		local itemdata = server.get_item_data(item_type)

		-- Change weapon held to this item collected, if it is holdable.
		if itemdata.slot then --if heldable[itemdata.category] then
			-- If it's a thing we can wield on hands, collect it and remove from world.
			local item_object = server.new_item(item_type)
			if not player.i[item_type] then
				server.select(player_id, item_type)
			end
			player.i[item_type] = item_object
		elseif itemdata.category == "armor" then
			if player.a == item_type then
				-- Nothing
			else
				-- Set the new armor
				player.a = item_type
			end
		elseif itemdata.category == "equipment" then
			if player.e[item_type] then
				-- dont collect
			else
				player.e[item_type] = true
			end
		end
	end -- for k,v in pairs({...}) do	
end

function server.collect(player_id, item_id)
	local item_object = share.items[item_id]
	if not item_object then
		return server.log(1, "error", "(collect) There is no item on the world with ID [" .. item_id .. "]")
	end
	local player = share.players[player_id]
	if not player then
		return server.log(1, "error", "(collect) There is no player on the world with ID [" .. player_id .. "]")
	end

	local item_type = item_object.it
	local itemdata = server.get_item_data(item_type)

	-- Change weapon held to this item collected, if it is holdable.
	if itemdata.slot then --if heldable[itemdata.category] then
		-- If it's a thing we can wield on hands, collect it and remove from world.
		if not player.i[item_type] then
			-- Remove item from map
			server.removeitem(item_id)

			-- Also we need to know if player already have the weapon
			item_object.x = nil
			item_object.y = nil

			player.i[item_type] = item_object
			server.select(player_id, item_type)
		end
	elseif itemdata.category == "armor" then
		if player.a == item_type then
			-- Nothing
		else
			local old_type = player.a
			local tx = item_object.x
			local ty = item_object.y

			-- Remove current item from the map
			server.removeitem(item_id)

			-- Spawn old armor on the ground of where the previous item was
			server.spawnitem(old_type, tx, ty)

			-- Set the new armor
			player.a = item_type
		end
	elseif itemdata.category == "equipment" then
		if player.e[item_type] then
			-- dont collect
		else
			player.e[item_type] = true
			server.removeitem(item_id)
		end
	end

	-- Call hook after collecting the item
	local ammo_in = item_object.am
	local ammo = item_object.ac
	local mode = item_object.m
	server.callhook("collect", player_id, item_id, item_type, ammo_in, ammo, mode)
end

function server.raycast(x1, y1, x2, y2)
	if not server.map then return false end

	local start_x, start_y = x1, y1
	-- First calculate map impacts
	-- If stopped into a wall, calculate until that wall point of impact
	-- Else, go with the original point
	local impact_x, impact_y, hit = server.map:hitscan(x1, y1, x2, y2, 1)
	local players = {}

	-- Now calculate bump collision
	local item_info, len = server.world:querySegmentWithCoords(start_x, start_y, impact_x, impact_y)
	for i = 1, len do
		local info = item_info[i]
		local object = info.item

		-- check if it's a player
		if object.ct == 1 and object.h > 0 then
			-- Update the values for the first player hit
			impact_x = info.x1
			impact_y = info.y1
			hit = true

			-- Stops at first impact
			return impact_x, impact_y, hit, item_info[1]
		end
	end

	-- returns point of impact (wall or player)
	-- And also the first object, if possible	
	return impact_x, impact_y, hit, item_info[1]
end

function server.hitscan(x1, y1, x2, y2)
	if not server.map then return false end

	local start_x, start_y = x1, y1
	-- First calculate map impacts
	-- If stopped into a wall, calculate until that wall point of impact
	-- Else, go with the original point
	local impact_x, impact_y, hit = server.map:hitscan(x1, y1, x2, y2, 1)
	local players = {}

	-- Now calculate bump collision
	local item_info, len = server.world:querySegmentWithCoords(start_x, start_y, impact_x, impact_y)
	for i = 1, len do
		local info = item_info[i]
		local object = info.item

		-- check if it's a player
		if object.ct == 1 and object.h > 0 then
			table.insert(players, object)
			hit = true
		end
	end

	return impact_x, impact_y, hit, players
end

function server.armor_to_item(value)
end

function server.item_to_armor(value)
end

function server.get_item_data(item_type)
	local itemdata = server.content.itemlist[item_type]
	if itemdata then
		return itemdata
	end
end

function server.item_is(item_type, cat)
	local itemdata = server.content.itemlist[item_type]
	if itemdata.category[cat] then
		return itemdata
	end
end

function server.get_item_held(peer_id)
	local player = share.players[peer_id]
	if not player then return 0 end
	local itemheld = player.ih or 0
	local itemdata = server.content.itemlist[itemheld]
	return itemheld, itemdata
end

function server.setpos(peer_id, x, y)
	if not server.clientExists(peer_id) then return false end
	x, y = floor(x), floor(y)

	local player = share.players[peer_id]
	player.x = x
	player.y = y
	player.last_tx = floor(x / 32)
	player.last_ty = floor(y / 32)
	server.log(1, "game",
		string.format(
			"player [ID: %s] setpos to [%s-%s] T:[%s-%s]",
			peer_id, x, y, floor(x / 32), floor(y / 32)))

	server.world:update(player, x - player.size / 2, y - player.size / 2)
	return true
end

function server.trigger(target_names, source_id, x, y, active_set)
	if not target_names or target_names == "" or not server.map then return end
	source_id = source_id or 0
	active_set = active_set or {}

	for sub_name in string.gmatch(target_names, "[^,]+") do
		sub_name = sub_name:match("^%s*(.-)%s*$")
		if sub_name ~= "" then
			-- Prevent infinite recursion / cyclic trigger loops
			if not active_set[sub_name] then
				active_set[sub_name] = true

				-- 1. Call global Lua "trigger" hook
				server.callhook("trigger", sub_name, source_id)

				-- 2. Find target entities registered with this name
				local targets = server.map:getEntitiesByName(sub_name)
				for i = 1, #targets do
					local e = targets[i]
					-- Call global Lua "triggerentity" hook
					server.callhook("triggerentity", e.name, source_id)

					-- Dispatch entity activation logic
					server.activate_entity(e, source_id, x, y, active_set)
				end

				active_set[sub_name] = nil
			end
		end
	end
end

function server.activate_entity(e, source_id, x, y, active_set)
	if not e or not server.map then return end

	local source_player = (source_id and source_id > 0) and share.players[source_id] or nil
	if e.onToggle then
		e:onToggle(source_player, source_id, server)
	end
	--[[
	-- Func_Teleport (70): Toggles disabled state
	if e.type == 70 and not e.onToggle then
		e.disabled = not e.disabled
		server.send("all", string.format("entitystate %d %d 70 %d", e.x, e.y, e.disabled and 1 or 0))

		-- Func_DynWall (71): Toggles open/closed state
	elseif e.type == 71 then
		e.state = (e.state == 1) and 0 or 1
		-- Sync DynWall state to clients
		server.send("all", string.format("entitystate %d %d 71 %d", e.x, e.y, e.state))

		-- Func_Message (72): Sends message to source player or all
	elseif e.type == 72 then
		local msg = e.string_settings[1] or ""
		if msg ~= "" then
			if source_id and source_id > 0 then
				server.send(source_id, "msg " .. msg)
			else
				server.send("all", "msg " .. msg)
			end
		end

		-- Func_GameAction (73): Runs action command via parse
	elseif e.type == 73 then
		local action_cmd = e.string_settings[1] or ""
		if action_cmd ~= "" then
			server.parse(source_id or 0, action_cmd)
		end

		-- Env_Sound (23): Plays sound asset
	elseif e.type == 23 then
		local sound_file = e.string_settings[1] or ""
		if sound_file ~= "" then
			server.send("all", string.format("sound %s %d %d", sound_file, e.x * 32 + 16, e.y * 32 + 16))
		end

		-- Trigger_Start (90): Fires its target trigger
	elseif e.type == 90 then
		if e.trigger and e.trigger ~= "" then
			server.trigger(e.trigger, source_id, x, y, active_set)
		end

		-- Trigger_Move (91): Fires its target trigger
	elseif e.type == 91 then
		if e.trigger and e.trigger ~= "" then
			server.trigger(e.trigger, source_id, x, y, active_set)
		end

		-- Trigger_Hit (92): Fires its target trigger
	elseif e.type == 92 then
		if e.trigger and e.trigger ~= "" then
			server.trigger(e.trigger, source_id, x, y, active_set)
		end

		-- Trigger_Use (93): Fires its target trigger
	elseif e.type == 93 then
		if e.trigger and e.trigger ~= "" then
			server.trigger(e.trigger, source_id, x, y, active_set)
		end

		-- Trigger_Delay (94): Delays then fires its target trigger (strs[1] in seconds)
	elseif e.type == 94 then
		local delay_sec = tonumber(e.string_settings[1]) or tonumber(e.number_settings[1]) or 0
		local delay_ms = math.floor(delay_sec * 1000)
		if e.trigger and e.trigger ~= "" then
			if delay_ms > 0 then
				server.timerex(delay_ms, 1, function()
					server.trigger(e.trigger, source_id, x, y)
				end)
			else
				server.trigger(e.trigger, source_id, x, y, active_set)
			end
		end

		-- Trigger_Once (95): Fires once then disables
	elseif e.type == 95 then
		if not e._triggered then
			e._triggered = true
			server.send("all", string.format("entitystate %d %d 95 1", e.x, e.y))
			if e.trigger and e.trigger ~= "" then
				server.trigger(e.trigger, source_id, x, y, active_set)
			end
		end

		-- Trigger_If (96): Fires its trigger
	elseif e.type == 96 then
		if e.trigger and e.trigger ~= "" then
			server.trigger(e.trigger, source_id, x, y, active_set)
		end
	end
	]]
end

function server.pausetime()
	share.game.pause_start = os.time()
	share.game.paused = true

	server.log(1, "game", "Game paused!")
	server.send("all", "log Game paused!")
end

function server.resumetime()
	share.game.timer_start = os.time() -
		(share.game.pause_start - share.game.timer_start)
	share.game.pause_start = 0
	share.game.paused = false

	server.log(1, "game", "Game resumed!")
	server.send("all", "log Game resumed!")
end

function server.setroundtime(time)
	share.game.timer = time
end

function server.settime(time)
	share.game.timer_start = os.time() + (time - share.game.timer)
end

function server.getcurrenttime()
	return os.time() - share.game.timer_start
end

function server.resettimer()
	share.game.timer_start = os.time()
end

function server.resetscores(peer_id)
	local playerscores = share.playerscores
	if peer_id and playerscores[peer_id] then
		playerscores[peer_id] = {
			s = 0,
			d = 0,
			a = 0,
			hk = 0,
			tk = 0,
			tbk = 0,
			mvp = 0,
		}
	end
end

function server.resetobjects()
	share.items   = {}
	share.bullets = {}
	share.objects = {}
end

function server.restart(seconds)
	if server.endround_flag then
		server.free_timer(server.endround_flag)
		server.endround_flag = false
	end

	server.callhook("startround_prespawn")
	local players = share.players
	-- Reset all players health and scores
	for peer_id, player in pairs(players) do
		if player.t > 0 then
			server.spawnplayer_silent(peer_id, player.x, player.y)
		end
		server.resetscores(peer_id)
	end
	-- Clear all items and entities from world
	server.resetobjects()
	server.resettimer()
	server.callhook("startround")

	server.message("all", "©255220000Round restart!@C")
	server.send("all", "restart")
end

function server.startround()
	if server.endround_flag then
		server.free_timer(server.endround_flag)
		server.endround_flag = false
	end

	if not server.gamemode_assert("startround_prespawn") then
		-- Create a generic startround routine.
		server.callhook("startround_prespawn")
		local players = share.players
		-- Reset all players health
		for peer_id, player in pairs(players) do
			server.sethealth(peer_id, player.mh)
		end
		-- Clear all items and entities from world
		server.resetobjects()
	else
		-- Let the gamemode decide what to do
		server.callhook("startround_prespawn")
	end

	server.resettimer()

	if not server.gamemode_assert("startround") then
		server.callhook("startround")
		server.message("all", "©255220000Round starting!@C")
	else
		server.callhook("startround")
	end

	-- Fire Trigger_Start (90) entities
	if server.map then
		local start_triggers = server.map:getEntities(90)
		for i = 1, #start_triggers do
			local st = start_triggers[i]
			if st.trigger and st.trigger ~= "" then
				server.trigger(st.trigger, 0)
			end
		end
	end
end

function server.endround(team_win, seconds)
	if not server.endround_flag then
		seconds = seconds or 5
		server.callhook("endround", team_win)

		if team_win == 0 then
			server.message("all", "©255220000Draw!@C")
		else
			local team = share.config.teams[team_win]
			if team then
				server.message("all", string.format("©%s%s wins!@C", team.color, team.name))
			else
				-- Consider it a draw since no correct team_id was found
				server.message("all", "©255220000Draw!@C")
			end
		end

		server.endround_flag = server.timerex(seconds * 1000, 1, server.startround)
	end
end

function server.respawnrequest(peer_id)
	if not server.gamemode_assert("respawnrequest") then
		server.spawnplayer(peer_id)
		return
	end
	-- Let gamemode handle the respawn
	-- Dont call hooks because this is meant to be called by the gamemode
	server.gamemode_call("respawnrequest", peer_id)
end

function server.changeteam(peer_id, team_id, look_id)
	if not server.clientExists(peer_id) then
		return false, "(changeteam) Player with this ID doesn't exist"
	end
	if not (share.config or share.config.teams) then return end
	local fate = server.callhook("team", peer_id, team_id)
	if fate == 1 then
		return false, "(changeteam) Refused by a mod"
	end
	local teams = share.config.teams
	local player = share.players[peer_id]
	team_id = team_id or math.random(1, #teams)
	local team = teams[team_id]
	if team_id > 0 and team then
		if team_id ~= player.t and player.h > 0 then
			-- TODO check for team balance
			-- TODO check for multiple changeteam attempts

			-- Kill this player if trying to change team while alive
			server.sethealth(peer_id, 0)
		end
		local look_str = "default.png"
		if team.looks then
			if not look_id then
				look_id = math.random(1, #team.looks)
			end
			look_str = team.looks[look_id].appearance
		end

		player.t = team_id
		player.p = look_str
	else
		player.t = 0
		-- Kill this player if trying to set to spectator mode
		server.sethealth(peer_id, 0)
	end
	-- Announcement of joining teams
	server.send("all", "log " .. player.n .. " joined ©" .. team.color .. team.name)
end

function server.dropitem(peer_id, item_type)
	if not server.clientExists(peer_id) then
		return false, "(dropitem) Player with this ID doesn't exist"
	end

	local player = share.players[peer_id]
	if not player then
		return false, "(dropitem) Player object not found"
	end

	if not server.content.itemlist[item_type] then
		return false, "(dropitem) This item TYPE doesn't exist"
	end

	if item_type == 0 or item_type == nil then
		return false, "(dropitem) There is nothing to drop [item 0/nil]"
	end

	local itemdata = server.get_item_data(item_type)
	local heldable = server.content.itemlist_slots

	if heldable[itemdata.category] and player.i[item_type] then
		server.reloadcancel(peer_id)
		local x, y = math.floor(player.x / 32), math.floor(player.y / 32)
		-- Hold the last reference to this item
		local item_object = player.i[item_type]

		-- Drop hook
		server.callhook("drop", peer_id, item_object.id, item_type, item_object.am, item_object.ac, 0, x, y)

		-- Spawn item on the ground with the exact same characteristics
		server.spawnitem(item_type, x, y, {
			ac = item_object.ac,
			am = item_object.am,
		})

		-- Erase it from player item table
		player.i[item_type] = nil

		-- Try to swap to the next item
		local items_ordered = {}
		for k, v in pairs(player.i) do
			table.insert(items_ordered, k)
		end
		table.sort(items_ordered)
		if items_ordered[1] then
			server.select(peer_id, items_ordered[1])
		else
			server.select(peer_id, 0)
		end
	end -- if heldable...

	return true
end

function server.use(peer_id)
	local player = share.players[peer_id]
	if not player or not server.map then return end

	local tx = math.floor(player.x / 32)
	local ty = math.floor(player.y / 32)

	-- Search for Trigger_Use (93) entity at player tile or adjacent 3x3 tiles
	local trigger_entity = nil
	for dx = -1, 1 do
		for dy = -1, 1 do
			local e = server.map:getEntityAt(tx + dx, ty + dy, 93)
			if e then
				trigger_entity = e
				break
			end
		end
		if trigger_entity then break end
	end

	local event = 0
	local data = 0
	local x, y = 0, 0

	if trigger_entity then
		event = 100
		data = 0
		x = trigger_entity.x
		y = trigger_entity.y

		if trigger_entity.trigger and trigger_entity.trigger ~= "" then
			server.trigger(trigger_entity.trigger, peer_id, x, y)
		end
	end

	server.callhook("use", peer_id, event, data, x, y)
end

function server.setitem(peer_id, item_type)
	if not server.clientExists(peer_id) then
		return false, "(setitem) Player with this ID doesn't exist"
	end

	local player = share.players[peer_id]
	if not player then
		return false, "(setitem) Player object not found"
	end

	if item_type == 0 or item_type == nil then
		server.select(peer_id, 0)
		return true
	end

	if not server.content.itemlist[item_type] then
		return false, "(setitem) This weapon ID doesn't exist"
	end


	local itemdata = server.get_item_data(item_type)
	local heldable = server.content.itemlist_slots

	if heldable[itemdata.category] and player.i[item_type] then
		server.select(peer_id, item_type)
	end
	--server.log(1, "game", string.format("set [ID:%s] item to [%s]", peer_id, item_type))
	return true
end

server.setweapon = server.setitem

function server.input_response(peer_id, input, seq)
	server.apply_input_to_player(peer_id, input)
end

function server.apply_input_to_player(peer_id, input)
	if is_dead(peer_id) then return end
	local player = share.players[peer_id]

	-- Movement vectors
	local h, v, w = 0, 0, 1
	if input["forward"] then v = -1 end
	if input["back"] then v = 1 end
	if input["left"] then h = -1 end
	if input["right"] then h = 1 end
	if input["walk"] then w = 0.5 end

	-- Detect changes in vectors based on peer input
	-- If there are changes fix the vector magnitude,
	-- And apply them on the player object
	if v ~= 0 or h ~= 0 then
		-- Magnitude
		local mag = math.sqrt(v * v + h * h)
		local scale
		if mag == 0 then
			v, h = 0, 0
		else
			scale = 1 / mag
			v, h = v * scale, h * scale
		end
		server.apply_forces_to_player(peer_id, v, h, w)
	end

	if input["drop"] then
		local item_type = player.ih
		server.dropitem(peer_id, item_type)
	end

	if input["use"] then
		server.use(peer_id)
	end

	if input["reload"] then
		server.reloadrequest(peer_id)
	end
end

function server.apply_forces_to_player(peer_id, v, h, w)
	if is_dead(peer_id) then return end

	local player = share.players[peer_id]
	local map = server.map
	if not map then return end

	-- Store old valuies
	local old_x = player.x
	local old_y = player.y
	local old_tx = math.floor(old_x / 32)
	local old_ty = math.floor(old_y / 32)

	-- Get the projected value from speed + direction
	local dx = player.s * h * w
	local dy = player.s * v * w

	-- Get the player size
	local half = math.floor(player.size / 2)

	-- Calculate this vector's collision with map
	local future_x, future_y = map:move_and_slide(player.size, player.x, player.y, dx, dy)

	-- Calculate player colliding with other objects
	local filter = server.player_collision_filter
	local current_x, current_y, collisions, length = server.world:move(player, future_x - half, future_y - half, filter)
	player.x = current_x + half
	player.y = current_y + half

	-- Collision handler
	for i = 1, length do
		local collision = collisions[i]

		local _type     = collision.type

		local object    = collision.other
		local itemRect  = collision.itemRect
		local otherRect = collision.otherRect
		local move      = collision.move
		local normal    = collision.normal
		local ti        = collision.ti
		local overlaps  = collision.overlaps

		--print(string.format("collided with %s [%s %s]", object, object.x, object.y))
		--print(serpent.line(object, server.stateDumpOpts))

		-- Collided with item
		if object.ct == 2 then
			-- Call the walkover callback
			local item_id = object.id
			local item_type = object.ih
			local ammo_in = object.am
			local ammo = object.ac
			local mode = object.m

			-- Check if player first touch it (by not overlapping)
			if not overlaps then
				-- TODO: resolve this callback return value.
				local collect = server.callhook("walkover", peer_id, item_id, item_type, ammo_in, ammo, mode)

				-- Add item to player inventory if possible/allowed
				if true then
					-- Call the collect function
					server.collect(peer_id, item_id)
				end
			end
		end
	end

	-- Store new values
	local new_x = player.x
	local new_y = player.y
	local new_tx = floor(new_x / 32)
	local new_ty = floor(new_y / 32)

	-- Check for entity triggers when entering a new tile
	if new_tx ~= player.last_tx or new_ty ~= player.last_ty then
		local walking_entity = server.map:getEntityAt(new_tx, new_ty, 70)
		if walking_entity and walking_entity.onWalk then
			walking_entity:onWalk(player)
			new_x = player.x
			new_y = player.y
			new_tx = floor(new_x / 32)
			new_ty = floor(new_y / 32)
		end
		player.last_tx = new_tx
		player.last_ty = new_ty
	end

	-- After collision is solved, run the callbacks
	if new_x ~= old_x or new_y ~= old_y then
		server.callhook("move", peer_id, new_x, new_y, floor(new_x), floor(new_y))
	end

	if new_tx ~= old_tx or new_ty ~= old_ty then
		server.callhook("movetile", peer_id, new_tx, new_ty)
	end
end

function server.player_collision_filter(self, other)
	if self.ct == 1 then
		if other.ct == 2 then -- item
			return "cross"  -- Ignore physics and register the collision
		elseif other.ct == 1 then -- player
			if other.h > 0 then
				return "slide" -- Apply physics to other players
			else
				return "cross"
			end
		end
	end
end

function server.tick()
	server.callhook("always")
end

function server.frame(dt)
	for peer_id, player in pairs(share.players) do
		server.resolve_action(peer_id, dt)
	end
	server.callhook("update", dt)
end

function server.resolve_action(peer_id, dt)
	local home = homes[peer_id]
	local player = share.players[peer_id]
	if not (home and player) then return end

	player.targetX = home.targetX or 0
	player.targetY = home.targetY or 0

	if player._attack1Timer > 0 then
		player._attack1Timer = player._attack1Timer - dt
	end
	if home.attack then
		-- Increment timer if player is pressing attack
		-- Dont go below 0
		while player._attack1Timer <= 0 do
			local cooldown = server.attack(peer_id) or 1
			if cooldown > 0 then
				player._attack1Timer = player._attack1Timer + cooldown
			end
		end
	end

	-- Check reload timers
	if player._reloadTimer > 0 then
		player._reloadTimer = player._reloadTimer - dt
		if player._reloadTimer <= 0 then
			player._reloadTimer = 0
			server.reload(peer_id)
		end
	end
end

function server.getWeaponHitbox(x, y, width, reach, angle, offset)
	local half_w = width / 2
	-- rectangle in front of player
	local weapon = {
		0, -half_w,
		0 + reach, -half_w,
		0 + reach, half_w,
		0, half_w
	}
	-- rotate and translate to position
	mlib.rotatePolygon(weapon, 0, 0, angle)
	mlib.translatePolygon(weapon, x, y)
	if offset then
		mlib.translatePolygonPolar(weapon, angle, offset)
	end
	return weapon
end

function server.attack(peer_id, dt)
	local player = share.players[peer_id]
	if is_dead(peer_id) then return end

	local itemheld, itemdata = server.get_item_held(peer_id)
	if not itemdata then return end

	-- Stop reloading action
	server.reloadcancel(peer_id)

	-- Get player position and target
	local mouse_x = player.targetX
	local mouse_y = player.targetY
	local player_x = player.x
	local player_y = player.y
	local player_angle = math.atan2(mouse_y - server.height / 2, mouse_x - server.width / 2)

	-- Get item attack mode
	local attack_data = itemdata.attack
	if not attack_data then return end
	local args = {}
	for arg in attack_data:gmatch("[^%s:]+") do
		table.insert(args, arg)
	end

	-- Get action data
	local action = table.remove(args, 1)
	if not action then return end

	-- Resolve action
	if action == "bullet" then
		-- Reduce bullet count
		local itemobject = player.i[itemheld]
		if itemobject then
			local ammo_mag = itemobject.am or 0
			local ammo_cap = itemobject.ac or 0
			if ammo_mag and ammo_cap then
				-- Check if player have enough bullets
				if ammo_mag > 0 then
					-- Decrease bullet count
					itemobject.am = itemobject.am - 1
				else
					return
				end
			end
		end

		-- How many bullets will spawn (in units)
		local spawn = tonumber(args[1]) or 1
		-- How far away they will be spread out (in degrees)
		local spread = tonumber(args[2]) or 1
		-- Frame delay of this weapon (in frames)
		local frame_delay = itemdata.frame_delay or 9
		-- True delay of this weapon (in seconds)
		local seconds = frame_delay / 60
		-- Broadcast to all peers that we attacked.
		server.send("all", string.format("attack %s", peer_id))

		-- In CS2D the range value is multiplied by 3
		local distance = itemdata.range * 3
		-- Calculate offset (distance from player center position)
		-- To make bullet exit out of muzzle instead of player.
		local offset = 20
		local offset_x = player_x + math.cos(player_angle) * offset
		local offset_y = player_y + math.sin(player_angle) * offset

		-- Call the attack hook
		server.callhook("attack", peer_id)

		if spawn == 1 then
			-- Skip with single shot
			server.fire(offset_x, offset_y, player_angle, distance, peer_id)
			return seconds
		end

		-- Multishot (from shotguns, etc.)
		local half = math.floor(spawn / 2)
		for i = 1, spawn do
			local subangle = player_angle + math.rad(i * spread - half * spread)
			server.fire(offset_x, offset_y, subangle, distance, peer_id)
		end
		return seconds
	end

	if action == "swing" then
		--local rpm = itemdata.frame_delay or 22
		local frame_delay = itemdata.frame_delay or 22
		-- Actions per second
		local seconds = frame_delay / 60
		-- Attack broadcast
		server.send("all", string.format("attack %s", peer_id))
		-- Call the attack hook
		server.callhook("attack", peer_id)
		-- Play the animation and hit detection
		server.swing(player_angle, peer_id)
		return seconds
	end
end

---@param start_x number
---@param start_y number
---@param distance number
---@param angle number
---@param peer_id number
function server.fire(start_x, start_y, angle, distance, peer_id)
	local itemheld, itemdata = server.get_item_held(peer_id)
	if not (itemheld and itemdata) then return end

	peer_id = peer_id or 0
	angle = angle or 0
	distance = distance or (32 * 10)

	local target_x = start_x + math.cos(angle) * distance
	local target_y = start_y + math.sin(angle) * distance

	local hit_x, hit_y, hit, players = server.hitscan(start_x, start_y, target_x, target_y)
	local hit_distance = distance
	if hit then
		local dx = hit_x - start_x
		local dy = hit_y - start_y
		hit_distance = math.sqrt(dx * dx + dy * dy)
	end

	for index, victim in pairs(players) do
		if victim.h > 0 then
			local attacker_id = peer_id or 0
			local victim_id = victim.id or 0
			local item_type = itemheld
			local damage = itemdata.damage

			-- This is a player vs player hit, so object_id in this case is 0
			server.hit(victim_id, attacker_id, item_type, damage, 0)
		end
	end
end

---Execute a melee swing weapon attack
---@param angle number
---@param peer_id number
function server.swing(angle, peer_id)
	local player = share.players[peer_id]
	local itemheld, itemdata = server.get_item_held(peer_id)
	if not (itemheld and itemdata) then return end

	local hitbox = server.getWeaponHitbox(
		player.x, player.y,
		itemdata.width, itemdata.range,
		angle,
		itemdata.offset
	)

	-- Query a box near the player, to get possible melee range candidates
	local box_size = 100
	local x = math.floor(player.x - box_size / 2)
	local y = math.floor(player.y - box_size / 2)
	local w = math.floor(box_size)
	local h = math.floor(box_size)
	local targets = server.world:queryRect(x, y, w, h)

	for index, target in ipairs(targets) do
		if target.ct == 1 and target.id ~= peer_id and target.h > 0 then
			local half = target.size
			local body = {
				-half, -half,
				half, -half,
				half, half,
				-half, half
			}
			mlib.translatePolygon(body, target.x, target.y)
			if mlib.polygonsCollide(hitbox, body) then
				local victim_id = target.id
				local attacker_id = peer_id
				local item_type = itemheld
				local damage = itemdata.damage
				-- Deal damage to target_id
				server.hit(victim_id, attacker_id, item_type, damage, 0)
			end
		end
	end
end

function server.reloadrequest(peer_id)
	-- Add a delay to reload peer_id held weapon
	local player = share.players[peer_id]

	-- Check if player is already reloading
	if player._reloadTimer > 0 then return end

	-- Check if player is alive
	if is_dead(peer_id) then return end

	-- Check if player can reload
	local itemheld, itemdata = server.get_item_held(peer_id)
	if not (itemdata and itemheld > 0) then return end
	local itemobject = player.i[itemheld]
	if not itemobject then return end
	if not (itemdata.ammo_mag and itemdata.ammo_mag) then return end -- Not reloadable
	if itemobject.am >= itemdata.ammo_mag then return end         -- Magazine full no reload
	if itemobject.ac <= 0 then return end                         -- No ammo no reload

	-- TODO: need to modularize reload action to
	-- support more than one reload action,
	-- specially for special weapon like portal gun

	-- Set reloading timer in seconds from frames
	local seconds = (itemdata.reload or 70) / 60
	player._reloadTimer = seconds

	-- Broadcast to all peers that we are reloading
	server.send("all", string.format("reload %s %s %s", peer_id, 1, seconds))
	-- Call hook
	-- action 0 = cancelled reloading
	-- action 1 = starting reload
	-- action 2 = done reloading
	server.callhook("reload", peer_id, 1, seconds)
end

function server.reload(peer_id)
	local player = share.players[peer_id]
	local itemheld, itemdata = server.get_item_held(peer_id)
	if not itemdata then return end

	local itemobject = player.i[itemheld]
	if not itemobject then return end

	local ammo_mag = itemobject.am or 0
	local ammo_cap = itemobject.ac or 0
	if ammo_mag and ammo_cap then
		-- This item is reloadable, lets subtract from reserve
		-- And add to magazine
		local magazine_capacity = itemdata.ammo_mag
		local ammo_reserve = itemobject.ac
		local ammo_to_add = math.min(magazine_capacity - ammo_mag, ammo_reserve)
		itemobject.am = itemobject.am + ammo_to_add
		itemobject.ac = itemobject.ac - ammo_to_add
	end
	server.send("all", string.format("reload %s %s %s", peer_id, 2, 0))
	server.callhook("reload", peer_id, 2, 0)
end

function server.reloadcancel(peer_id)
	local player = share.players[peer_id]
	if not player then return end
	if player._reloadTimer <= 0 then return end
	local remainingReloadTime = player._reloadTimer
	player._reloadTimer = 0
	server.send("all", string.format("reload %s %s %s", peer_id, 0, remainingReloadTime))
	server.callhook("reload", peer_id, 0, remainingReloadTime)
end

---Calls a hook. There might be an equivalent in gamemode scripts
---@param hook_name string
---@param ... any
---@return any
function server.callhook(hook_name, ...)
	local fate
	if server.hooks[hook_name] then
		-- Call internal hook function
		fate = server.gamemode_call(hook_name, ...)

		-- Call modder hook function (if exists)
		local hooks = server.hooks[hook_name]
		for func_name in pairs(hooks) do
			-- [TODO] If there is more than one fate, we have to add
			-- A policy determining what to do with multiple results
			-- Proposed results are merge, keep the last one, or
			-- if it's a string, join them with commas
			fate = server.env_call(func_name, ...)
			--[[
			if type(ongoing_fate) == "string" then
				fate = (fate or "") .. "," .. ongoing_fate
			end
			if type(ongoing_fate) == "number" then
				-- Compare first with internal hook fate result
			end]]
		end
	end
	return fate
end

---Creates a timer which will call the Lua function "function"
---after a certain time in milliseconds (time).
---Moreover it can pass an optional string parameter ("parameter")
---to this function. The timer calls the function once by default.
---However you can call it several times by entering
---the optional count parameter (count).
---Using 0 or negative count values will make the timer
---call the function infinite times or until it is removed via freetimer.
---@param miliseconds number
---@param function_name string
---@param parameter string?
---@param count number?
---@return number
function server.new_timer(miliseconds, function_name, parameter, count)
	server.timers = server.timers or {}
	count = count or 1
	miliseconds = miliseconds or 1000
	function_name = function_name or ""
	parameter = parameter or ""

	local timer_id = #server.timers + 1
	local timer_seconds = miliseconds / 1000
	server.timers[timer_id] = {
		seconds = timer_seconds, -- Time is in milliseconds, so we divide by 1000 to get seconds
		function_name = function_name,
		parameter = parameter,
		count = count,
		accumulator = 0,
	}
	return timer_id
end

---comment
---@param miliseconds number
---@param count number
---@param f function
---@param ... any
---@return integer|nil
function server.timerex(miliseconds, count, f, ...)
	if not f then return end
	server.timers = server.timers or {}
	count = count or 1
	miliseconds = miliseconds or 1000

	local args = { ... }
	local timer_id = #server.timers + 1
	local timer_seconds = miliseconds / 1000
	server.timers[timer_id] = {
		seconds = timer_seconds, -- Time is in milliseconds, so we divide by 1000 to get seconds
		lambda = f,
		args = args,
		count = count,
		accumulator = 0,
	}

	--print(string.format("queueing %s [ID:%s] [timer: %s] [count:%s] ", f, timer_id, miliseconds, count))
	return timer_id
end

---Removes timers which call
---the specified "function" with the specified "parameter".
---If "parameter" is not set (or ""),
---all timers with the matching "function" will be removed.
---If neither "function" nor "parameter" is set (or if both are ""),
---this will remove ALL existing timers.
---Once a timer has been removed it won't be executed anymore.
---Of course you can create the same time again if you want to.
---@param timer_id number
function server.free_timer(timer_id)
	server.timers = server.timers or {}
	local t = server.timers[timer_id]
	--if t then
	--print("free: ", t.lambda, t.seconds*1000, timer_id)
	--end
	server.timers[timer_id] = nil
end

function server.free_timer_by_name(function_name, parameter)
	server.timers = server.timers or {}
	function_name = function_name or ""
	parameter     = parameter or ""

	if function_name == "" and parameter == "" then
		server.timers = {}
		return
	end

	for timer_id, timer in pairs(server.timers) do
		if timer.function_name == function_name then
			if timer.parameter == parameter or parameter == "" then
				server.timers[timer_id] = nil
			end
		end
	end
end

function server.call_timer_function(timer_id)
	local timer = server.timers[timer_id]
	if not timer then return end
	if timer.count > 0 then
		timer.count = timer.count - 1
	end

	if timer.count == 0 then
		server.timers[timer_id] = nil
		-- Destroy timer
		--print("timer "..timer_id.." destroyed (count:"..timer.count..")")
	end

	if timer.lambda and type(timer.lambda) == "function" then
		--print(string.format("calling %s [ID:%s] [timer: %s] [count:%s] ", timer.lambda, timer_id, timer.seconds*1000, timer.count))

		local func = timer.lambda
		func(unpack(timer.args))
	else
		server.env_call(timer.function_name, timer.parameter)
	end
end

local second_accumulator = 0
local ms100_accumulator = 0
local minute_accumulator = 0

---Updates the server.
---@param dt number
function server.update(dt)
	server.preupdate(dt)
	server.postupdate(dt)

	second_accumulator = second_accumulator + dt
	while second_accumulator >= 1 do
		server.callhook("second")
		second_accumulator = second_accumulator - 1
	end

	ms100_accumulator = ms100_accumulator + dt
	while ms100_accumulator >= 0.1 do
		server.callhook("ms100")
		ms100_accumulator = ms100_accumulator - 0.1
	end

	minute_accumulator = minute_accumulator + dt
	while minute_accumulator >= 60 do
		server.callhook("minute")
		minute_accumulator = minute_accumulator - 60
	end

	for timer_id, timer in pairs(server.timers) do
		timer.accumulator = timer.accumulator + dt
		while timer.accumulator >= timer.seconds do
			server.call_timer_function(timer_id)
			timer.accumulator = timer.accumulator - timer.seconds
		end
	end
end

return server
