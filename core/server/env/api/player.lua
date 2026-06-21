-- Player-related CS2D API functions

return function(cs2dAPI, server)
	local share = server.share
	local PLAYER_FUNCTIONS = {
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		-- Identity & Logins & Language
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		exists = function(player)
			if player then
				return true
			end
			return false
		end,

		name = function(player)
			return player.n
		end,

		ip = function(player, peer_id)
			local enet_identifier = tostring(server.getENetPeer(peer_id))
			return enet_identifier:match("(.+):.+")
		end,

		port = function(player, peer_id)
			local enet_identifier = tostring(server.getENetPeer(peer_id))
			return enet_identifier:match(".+:(.+)")
		end,

		usgn = function(player, peer_id)
			return 0
		end,

		usgnname = function(player, peer_id)
			return ""
		end,

		steamid = function(player, peer_id)
			return "0"
		end,

		steamname = function(player, peer_id)
			return ""
		end,

		bot = function(player, peer_id)
			return false
		end,

		rcon = function(player, peer_id)
			return false
		end,

		language = function(player, peer_id)
			return "English"
		end,

		language_iso = function(player, peer_id)
			return "US"
		end,

		-- Team & Appearance

		team = function(player, peer_id)
			return player.t
		end,

		favteam = function(player, peer_id)
			return ""
		end,

		look = function(player, peer_id)
			return player.p
		end,

		sprayname = function(player, peer_id)
			return ""
		end,

		spraycolor = function(player, peer_id)
			return "255255255"
		end,
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		-- Mouse position & Screen setup
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		mousex = function(player, peer_id)
			if player.h > 0 then
				return player.targetX
			else
				return -1
			end
		end,

		mousey = function(player, peer_id)
			if player.h > 0 then
				return player.targetY
			else
				return 1
			end
		end,

		mousemapx = function(player, peer_id)
			if player.h > 0 then
				local x, y = player.x, player.y
				local mousex, mousey = player.targetX, player.targetY
				local mapx = x + mousex - math.floor(server.width / 2)
				return mapx
			else
				return -1
			end
		end,

		mousemapy = function(player, peer_id)
			if player.h > 0 then
				local x, y = player.x, player.y
				local mousex, mousey = player.targetX, player.targetY
				local mapy = y + mousey - math.floor(server.height / 2)
				return mapy
			else
				return -1
			end
		end,

		mousedist = function(player, peer_id)
			if player.h > 0 then
				local x, y = player.x, player.y
				local mousex, mousey = player.targetX, player.targetY
				local abs_x = mousex - math.floor(server.width / 2)
				local abs_y = mousey - math.floor(server.height / 2)
				local dist = math.sqrt(abs_x * abs_x + abs_y * abs_y)
				return dist
			else
				return -1
			end
		end,

		screenw = function(player, peer_id)
			local screen_width = server.getSettings(peer_id, "screen_width")
			return screen_width
		end,

		screenh = function(player, peer_id)
			local screen_height = server.getSettings(peer_id, "screen_height")
			return screen_height
		end,

		windowed = function(player, peer_id)
			local fullscreen = server.getSettings(peer_id, "fullscreen")
			return not (fullscreen)
		end,

		widescreen = function(player, peer_id)
			local wide = server.getSettings(peer_id, "widescreen")
			return wide
		end,

		micsupport = function(player, peer_id)
			return false
		end,
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		-- Position
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		x = function(player, peer_id)
			return player.x
		end,

		y = function(player, peer_id)
			return player.y
		end,

		tilex = function(player, peer_id)
			return math.floor(player.x / 32)
		end,

		tiley = function(player, peer_id)
			return math.floor(player.y / 32)
		end,

		rot = function(player, peer_id)
			local x, y = player.x, player.y
			local mousex, mousey = player.targetX, player.targetY
			local abs_x = mousex - math.floor(server.width / 2)
			local abs_y = mousey - math.floor(server.height / 2)
			local angle = math.atan2(mousex - abs_x, mousey - abs_y) + math.pi / 2
			return angle
		end,
		
		pos = function(player, peer_id)
			return player.x, player.y
		end,
		
		tilepos = function(player, peer_id)
			return math.floor(player.x / 32), math.floor(player.y / 32)
		end,
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		-- Stats
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		health = function(player, peer_id)
			return player.h
		end,

		maxhealth = function(player, peer_id)
			return player.mh
		end,

		armor = function(player, peer_id)
			return player.a
		end,

		money = function(player, peer_id)
			return player.m
		end,

		score = function(player, peer_id)
			local playerscores = share.playerscores
			if not playerscores then
				return 0
			end
			return playerscores[peer_id].s or 0
		end,

		deaths = function(player, peer_id)
			local playerscores = share.playerscores
			if not playerscores then
				return 0
			end
			return playerscores[peer_id].d or 0
		end,

		teamkills = function(player, peer_id)
			local playerscores = share.playerscores
			if not playerscores then
				return 0
			end
			return playerscores[peer_id].tk or 0
		end,

		hostagekills = function(player, peer_id)
			local playerscores = share.playerscores
			if not playerscores then
				return 0
			end
			return playerscores[peer_id].hk or 0
		end,

		teambuildingkills = function(player, peer_id)
			local playerscores = share.playerscores
			if not playerscores then
				return 0
			end
			return playerscores[peer_id].tbk or 0
		end,

		mvp = function(player, peer_id)
			local playerscores = share.playerscores
			if not playerscores then
				return 0
			end
			return playerscores[peer_id].mvp or 0
		end,

		assists = function(player, peer_id)
			local playerscores = share.playerscores
			if not playerscores then
				return 0
			end
			return playerscores[peer_id].a or 0
		end,

		ping = function(player, peer_id)
			return server.getPing(peer_id) or 0
		end,

		idle = function(player, peer_id)
			return 0
		end,

		speedmod = function(player, peer_id)
			return player.s or 0
		end,

		spectating = function(player, peer_id)
			return 0
		end,

		ai_flash = function(player, peer_id)
			return 0
		end,
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		-- Equipment
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		weapontype = function(player, peer_id)
			return player.ih
		end,

		weaponmode = function(player, peer_id)
			return 0
		end,

		nightvision = function(player, peer_id)
			if player.e[59] then
				return true
			end
		end,

		defusekit = function(player, peer_id)
			if player.e[56] then
				return true
			end
		end,

		gasmask = function(player, peer_id)
			if player.e[60] then
				return true
			end
		end,

		bomb = function(player, peer_id)
			if player.i[55] then
				return true
			end
		end,

		flag = function(player, peer_id)
			if player.i[70] or player.i[71] then
				return true
			end
		end,
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		-- Actions & voting
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

		reloading = function(player, peer_id)
			if player.r > 0 then
				return true
			end
		end,

		process = function(player, peer_id)
			return player.pi
		end,

		votekick = function(player, peer_id)
			return player.vk or 0
		end,

		votemap = function(player, peer_id)
			return player.vm or ""
		end,
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
		-- Tables
		--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

		---@param team_id? number
		count = function(team_id)
			team_id = team_id or 0
			local players = share.players
			local count = 0
			for index, player in pairs(players) do
				if team_id == 0 or player.t == team_id then
					count = count + 1
				end
			end
			return count
		end,

		apply = function(f)
			local players = share.players
			if f and type(f) == "function" then
				for index, player in pairs(players) do
					f(player.id)
				end
			end
		end,


		---@param team_id? number
		table = function(team_id)
			team_id = team_id or 0
			local players = share.players
			local player_table = {}
			if not players then
				return player_table
			end
			for index, player in pairs(players) do
				if team_id == 0 or player.t == team_id then
					table.insert(player_table, player.id)
				end
			end
			return player_table
		end,

		tableliving = function()
			local players = share.players
			local player_table = {}
			if not players then
				return player_table
			end
			for index, player in pairs(players) do
				if player.h > 0 then
					table.insert(player_table, player.id)
				end
			end
			return player_table
		end,

		-- team1 & team2 kept for legacy
		team1 = function()
			local players = share.players
			local player_table = {}
			if not players then
				return player_table
			end
			for index, player in pairs(players) do
				if player.t == 1 then
					table.insert(player_table, player.id)
				end
			end
			return player_table
		end,

		team2 = function()
			local players = share.players
			local player_table = {}
			if not players then
				return player_table
			end
			for index, player in pairs(players) do
				if player.t == 2 then
					table.insert(player_table, player.id)
				end
			end
			return player_table
		end,

		team1living = function()
			local players = share.players
			local player_table = {}
			if not players then
				return player_table
			end
			for index, player in pairs(players) do
				if player.t == 1 and player.h > 0 then
					table.insert(player_table, player.id)
				end
			end
			return player_table
		end,

		team2living = function()
			local players = share.players
			local player_table = {}
			if not players then
				return player_table
			end
			for index, player in pairs(players) do
				if player.t == 2 and player.h > 0 then
					table.insert(player_table, player.id)
				end
			end
			return player_table
		end,

	}

	cs2dAPI.player = function(peer_id, parameter, ...)
		if peer_id == 0 then
			if PLAYER_FUNCTIONS[parameter] then
				local f = PLAYER_FUNCTIONS[parameter]
				return f(...)
			end
		end

		local players = share.players
		if not players then return false end
		local player = players[peer_id]
		if not player then return false end

		if PLAYER_FUNCTIONS[parameter] then
			local f = PLAYER_FUNCTIONS[parameter]
			return f(player, peer_id)
		end
	end

	cs2dAPI.playerammo = function(player_id, type)
		-- void
	end

	cs2dAPI.playerweapons = function(player_id)
		-- void
	end
end
