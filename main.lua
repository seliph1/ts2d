--				NO GLITCHES?
--		⠀⣞⢽⢪⢣⢣⢣⢫⡺⡵⣝⡮⣗⢷⢽⢽⢽⣮⡷⡽⣜⣜⢮⢺⣜⢷⢽⢝⡽⣝
--		⠸⡸⠜⠕⠕⠁⢁⢇⢏⢽⢺⣪⡳⡝⣎⣏⢯⢞⡿⣟⣷⣳⢯⡷⣽⢽⢯⣳⣫⠇
--		⠀⠀⢀⢀⢄⢬⢪⡪⡎⣆⡈⠚⠜⠕⠇⠗⠝⢕⢯⢫⣞⣯⣿⣻⡽⣏⢗⣗⠏
--		⠀ ⠀⠪⡪⡪⣪⢪⢺⢸⢢⢓⢆⢤⢀⠀⠀⠀⠀⠈⢊⢞⡾⣿⡯⣏⢮⠷⠁⠀⠀
--		⠀⠀⠀⠈⠊⠆⡃⠕⢕⢇⢇⢇⢇⢇⢏⢎⢎⢆⢄⠀⢑⣽⣿⢝⠲⠉⠀⠀⠀⠀ ⠀
--		⠀⠀⠀⠀⡿⠂⠠⠀⡇⢇⠕⢈⣀⠀⠁⠡⠣⡣⡫⣂⣿⠯⢪⠰⠂⠀⠀⠀⠀ ⠀
--		⠀⠀⠀⡦⡙⡂⢀⢤⢣⠣⡈⣾⡃⠠⠄⠀⡄⢱⣌⣶⢏⢊⠂⠀⠀⠀⠀⠀⠀ ⠀
--		⠀⠀⠀⢝⡲⣜⡮⡏⢎⢌⢂⠙⠢⠐⢀⢘⢵⣽⣿⡿⠁⠁⠀⠀⠀⠀⠀⠀⠀ ⠀⠀
--		⠀⠀⠨⣺⡺⡕⡕⡱⡑⡆⡕⡅⡕⡜⡼⢽⡻⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀
--		⠀⣼⣳⣫⣾⣵⣗⡵⡱⡡⢣⢑⢕⢜⢕⡝⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀
--		⣴⣿⣾⣿⣿⣿⡿⡽⡑⢌⠪⡢⡣⣣⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀
--		⡟⡾⣿⢿⢿⢵⣽⣾⣼⣘⢸⢸⣞⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀
--		⠁⠇⠡⠩⡫⢿⣝⡻⡮⣒⢽⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀
---@diagnostic disable: duplicate-set-field, undefined-field, redundant-parameter

---------------------------------------------------------------------------------------
-- =============================================================================
-- Suporte a pastas externas quando executando como binário fundido (fused).
-- Monta o diretório do executável para expor gfx, sfx, logos, sys, maps.
-- =============================================================================
if love.filesystem.isFused() then
	local base_dir = love.filesystem.getSourceBaseDirectory()
	if base_dir then
		love.filesystem.mount(base_dir, "")
		-- Fallback para desenvolvimento caso o binário esteja dentro de build/
		if not love.filesystem.getInfo("gfx") and not love.filesystem.getInfo("maps") then
			local parent_dir = base_dir:match("^(.*)[/\\][^/\\]+$")
			if parent_dir then
				love.filesystem.mount(parent_dir, "")
			end
		end
	end
end

-- =============================================================================
-- Modo servidor dedicado headless: `love . --server`  (ou `lovec . --server`).
-- Roda o servidor vendorizado em core/server/ e encerra o chunk antes de
-- carregar qualquer coisa do cliente.
-- =============================================================================
do
	local is_server = false
	for _, a in ipairs(arg or {}) do
		if a == "--server" or a == "server" then
			is_server = true
			break
		end
	end
	if not is_server and love.filesystem then
		if love.filesystem.getInfo and (love.filesystem.getInfo("is_server") or love.filesystem.getInfo("core/is_server")) then
			is_server = true
		elseif love.filesystem.isFused and love.filesystem.isFused() then
			local src = (love.filesystem.getSource and love.filesystem.getSource()) or ""
			if src:lower():match("server") then
				is_server = true
			end
		end
	end
	if not is_server and arg then
		for i = -2, 0 do
			if arg[i] and tostring(arg[i]):lower():match("server") then
				is_server = true
				break
			end
		end
	end
	if is_server then
		local base = "core/server/"
		love.filesystem.setRequirePath(base .. "?.lua;" .. base .. "?/init.lua;" .. love.filesystem.getRequirePath())
		local server = require "server"
		function love.load(args)
			for i, a in ipairs(args or {}) do
				if a == "--run-script" and args[i + 1] then
					dofile(args[i + 1])
					love.event.quit(0)
					return
				end
			end
			local map = nil
			for _, a in ipairs(args or {}) do
				if a ~= "--server" and a ~= "server" and not a:match("^%-") then
					map = a
					break
				end
			end
			local ok, err = xpcall(function() server.load(map) end, debug.traceback)
			if not ok then
				print("SERVER CRASH TRACEBACK:\n" .. tostring(err))
				love.event.quit(1)
				return
			else
				print("SERVER LOADED SUCCESSFULLY")
				for _, a in ipairs(args or {}) do
					if a == "--test" or a == "--quit" then
						love.event.quit(0)
						return
					end
				end
			end
		end

		function love.update(dt) server.update(dt) end

		function love.quit() if server.shutdown then server.shutdown() end end

		return
	end
end

local loveframes  = require "lib.loveframes"
local console     = require "core.interface.console"
local ui          = require "core.interface.ui"
local client      = require "core.client"
--local discordRPC	= require "lib.discordRPC"
local discordRPC

local initializer = {
	["debug"] = function()
		-- VS Code debugger
		local lldebugger = require "lldebugger"
		if lldebugger then
			lldebugger.start()
		end
	end,

	["fused"] = function()
		local base_dir = love.filesystem.getSourceBaseDirectory()
		if love.getVersion() == 12 then
			assert(love.filesystem.mountFullPath(base_dir, "", "readwrite"), "failed to mount")
		else
			--assert(love.filesystem.mount(base_dir, ""), "failed to mount")
		end
	end,

	["discord"] = function()
		if discordRPC then
			discordRPC.initialize(require "core.applicationId", true)
			function discordRPC.ready(userId, username, discriminator, avatar)
				print(string.format("Discord: ready (%s, %s, %s, %s)", userId, username, discriminator, avatar))
			end

			function discordRPC.disconnected(errorCode, message)
				print(string.format("Discord: disconnected (%d: %s)", errorCode, message))
			end

			function discordRPC.errored(errorCode, message)
				print(string.format("Discord: error (%d: %s)", errorCode, message))
			end

			function discordRPC.joinGame(joinSecret)
				print(string.format("Discord: join (%s)", joinSecret))
			end

			function discordRPC.spectateGame(spectateSecret)
				print(string.format("Discord: spectate (%s)", spectateSecret))
			end

			function discordRPC.joinRequest(userId, username, discriminator, avatar)
				print(string.format("Discord: join request (%s, %s, %s, %s)", userId, username, discriminator, avatar))
				discordRPC.respond(userId, "yes")
			end
		end
	end,
}


function love.load(arguments)
	if love.getVersion() ~= 12 then
		love.graphics.newTextBatch = love.graphics.newText
	end

	if arguments and type(arguments) == "table" then
		for index, argument in pairs(arguments) do
			if initializer[argument] then
				initializer[argument]()
			end
		end
	end
	love.keyboard.setTextInput(true)
	client.load()
end

function love.update(dt)
	if discordRPC then
		discordRPC.update(dt)
	end

	loveframes.update(dt)
	client.update(dt)
end

function love.draw()
	client.draw()
	loveframes.draw()
end

function love.mousepressed(x, y, button, istouch, presses)
	loveframes.mousepressed(x, y, button, istouch, presses)
	if loveframes.GetInputObject() == false and loveframes.GetCollisionCount() < 1 then
		client.mousepressed(x, y, button, istouch, presses)
	end
end

function love.mousereleased(x, y, button, istouch, presses)
	loveframes.mousereleased(x, y, button, istouch, presses)
	client.mousereleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
	loveframes.mousemoved(x, y, dx, dy, istouch)
	client.mousemoved(x, y)
end

function love.wheelmoved(x, y)
	loveframes.wheelmoved(x, y)
	client.wheelmoved(x, y)
end

function love.keypressed(key, unicode)
	loveframes.keypressed(key, unicode)
	if not loveframes.GetInputObject() then
		client.keypressed(key)
	end
end

function love.keyreleased(key, unicode)
	loveframes.keyreleased(key)
	client.keyreleased(key)
end

function love.textinput(text)
	loveframes.textinput(text)
end

function love.quit()
	if client.stopListenServer then client.stopListenServer() end
	if discordRPC then
		discordRPC.shutdown()
	end
end

function love.resize(w, h)
	client.resize(w, h)
end
