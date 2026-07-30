-- Runtime environment setup for gamemode and server scripts

return function(cs2dAPI, BASE_ENV, server)
	local GAMEMODE_ENV = {}
	local SERVER_ENV = {}
	------------------------------------------------------------------------
	-- PRELOADED PACKAGES
	------------------------------------------------------------------------
	BASE_ENV.package.preload = {
		["timerex"] = function()
			return server.timerex
		end,

		["serpent"] = function()
			local serpent = require("lib.serpent")
			return serpent
		end,
	}
	------------------------------------------------------------------------
	-- ENVIRONMENT CALL FUNCTIONS
	------------------------------------------------------------------------
	function server.env_call(func, ...)
		if not SERVER_ENV._G[func] then
			server.log(7, "error", string.format('Lua: Cannot call function "%s" (Is your function local?).', func))
			return
		end
		local status, callback_value = pcall(SERVER_ENV._G[func], ...)
		if not status then
			server.log(7, "error", callback_value)
		end
		return callback_value
	end

	function server.gamemode_change(mode_id)
		GAMEMODE_ENV.gamemode = mode_id
	end

	function server.gamemode_assert(function_name)
		local current_gamemode = GAMEMODE_ENV.gamemode
		if not (
				GAMEMODE_ENV.gamemodes[current_gamemode]
				and
				GAMEMODE_ENV.gamemodes[current_gamemode][function_name]
			)
		then
			return false
		end
		return true
	end

	function server.gamemode_call(function_name, ...)
		local current_gamemode = GAMEMODE_ENV.gamemode
		if not (
				GAMEMODE_ENV.gamemodes[current_gamemode]
				and
				GAMEMODE_ENV.gamemodes[current_gamemode][function_name]
			)
		then
			return false
		end

		local func = GAMEMODE_ENV.gamemodes[current_gamemode][function_name]
		local status, callback_value = pcall(func, ...)
		if not status then
			server.log(7, "error", callback_value)
		end
		return callback_value
	end

	------------------------------------------------------------------------
	-- GAMEMODE SCRIPT ENVIRONMENT
	------------------------------------------------------------------------
	GAMEMODE_ENV._G = GAMEMODE_ENV
	for name, data in pairs(cs2dAPI) do
		GAMEMODE_ENV[name] = data
	end

	for address, data in pairs(BASE_ENV) do
		GAMEMODE_ENV[address] = data
	end

	function GAMEMODE_ENV.getfiles()
		local files = {}
		for index, filename in pairs(love.filesystem.getDirectoryItems("core/server/core/modes")) do
			if filename:match("%.lua$") then
				table.insert(files, filename)
			end
		end
		return files
	end

	function GAMEMODE_ENV.dofile(filename)
		local full_filename = "core/server/core/modes/" .. filename
		if love.filesystem.getInfo(full_filename) then
			local file = love.filesystem.load(full_filename)
			setfenv(file, GAMEMODE_ENV)
			return file
		end
	end

	GAMEMODE_ENV.addhook = nil
	GAMEMODE_ENV.freehook = nil
	GAMEMODE_ENV.gamemode = 0
	GAMEMODE_ENV.gamemodes = {}


	-- gamemode.lua entrypoint
	local status, entrypoint = pcall(love.filesystem.load, "core/server/core/gamemode.lua")
	if status then
		setfenv(entrypoint, GAMEMODE_ENV)
		local entrypoint_output = { pcall(entrypoint) }
		if not entrypoint_output[1] then
			server.log(7, "error", entrypoint_output[2])
		end
	else
		local error_message = tostring(entrypoint)
		error_message = string.gsub(error_message, "\n", "")
		server.log(7, "error", error_message)
	end

	------------------------------------------------------------------------
	-- SERVER SCRIPT ENVIRONMENT
	------------------------------------------------------------------------

	for address, data in pairs(cs2dAPI) do
		SERVER_ENV[address] = data
	end

	for address, data in pairs(BASE_ENV) do
		SERVER_ENV[address] = data
	end
	SERVER_ENV._G = SERVER_ENV

	local mp_luaserver = "sys/lua/server.lua"
	-- server.lua entrypoint
	server.log(7, "lua", string.format("Lua: Parsing Lua server script (mp_luaserver = '%s')", mp_luaserver))
	local status, entrypoint = pcall(love.filesystem.load, mp_luaserver)
	if status then
		setfenv(entrypoint, SERVER_ENV)
		local entrypoint_output = { pcall(entrypoint) }
		if not entrypoint_output[1] then
			server.log(7, "error", entrypoint_output[2])
		end
	else
		local error_message = tostring(entrypoint)
		error_message = string.gsub(error_message, "\n", "")
		server.log(7, "error", error_message)
	end

	-- Store this pointer to be available for server table
	server.env = SERVER_ENV
end
