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
local debuglaunch = false
local lldebugger
for k,v in pairs(arg) do
	if v == "showfps" then showfps = true end
	if v == "debug" then
		debuglaunch = true
		-- VS Code debugger
		lldebugger = require "lldebugger"
		lldebugger.start()
		end
	if v == "ui" then
		love.filesystem.load("uidebug/uidebug.lua") ()

		-- Skip all the code below.
		do return end
	end
end
---------------------------------------------------------------------------------------
local loveframes 	= require "lib.loveframes"
local client 		= require "client"
local ui 			= require "core.interface.ui"

function love.load()
	client.load()
end

function love.update( dt )
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
end

function love.resize(w, h)
	client.resize(w, h)
end
