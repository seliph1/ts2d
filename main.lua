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
---@diagnostic disable: duplicate-set-field

local showfps = false
local fused = true
local lldebugger
for k,v in pairs(arg) do
	if v == "showfps" then showfps = true end
	if v == "debug" then
		-- VS Code debugger
		lldebugger = require "lldebugger"
		lldebugger.start()
	end

	if v == "ui" then
		love.filesystem.load("uidebug/uidebug.lua") ()
		-- Skip all the code below.
		do return end
	end

	if v == "fused" then
		fused = true
	end
end

---------------------------------------------------------------------------------------
if fused or love.filesystem.isFused() then
	local base_dir = love.filesystem.getSourceBaseDirectory()
	if love.getVersion() == 12 then
		assert(love.filesystem.mountFullPath(base_dir, "", "readwrite"), "failed to mount")
	else
		--assert(love.filesystem.mount(base_dir, ""), "failed to mount")
	end
end

local loveframes 	= require "lib.loveframes"
local client 		= require "client"
local ui 			= require "core.interface.ui"
local discordRPC	= require "lib.discordRPC"
local applicationId	= require "lib.applicationId"

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


function love.load()
    discordRPC.initialize(applicationId, true)

	love.keyboard.setTextInput(true)
	client.load()
end

function love.update( dt )
	discordRPC.update( dt )

	loveframes.update(dt)
	client.update(dt)

	if showfps then
		love.window.setTitle( tostring( love.timer.getFPS() ) )
	end
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
	discordRPC.shutdown()
end

function love.resize(w, h)
	client.resize(w, h)
end
