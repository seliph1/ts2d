---@diagnostic disable: duplicate-set-field

local loveframes 	= require "lib/loveframes"
local client 		= require "client"
local ui 			= require "core/interface/ui"

--Console = require "core/interface/console"
--require "lib/lovedebug"

function love.load()
	client.load()
end

function love.update( dt )
	client.update(dt)
	loveframes.update(dt)
end

function love.draw()
	client.draw()
	loveframes.draw()
end

function love.mousepressed(x, y, button, istouch, presses)
	client.mousepressed(x, y, button, istouch, presses)
	loveframes.mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
	client.mousereleased(x, y, button, istouch, presses)
	loveframes.mousereleased(x, y, button, istouch, presses)
end

function love.keypressed(key, unicode)
	if (key == "escape") then os.exit(0) end
	if (key=="f1") then
		local state = loveframes.config["DEBUG"]
		loveframes.config["DEBUG"] = not state
	elseif key == "'" then
		if Console then
			Console.frame:ToggleVisibility()
		end
	end
	loveframes.keypressed(key, unicode)
	client.keypressed(key)
end

function love.keyreleased(key, unicode)
	client.keyreleased(key)
	loveframes.keyreleased(key)
end

function love.mousemoved(x, y, dx, dy, istouch)
	client.mousemoved(x, y)
	loveframes.mousemoved(x, y, dx, dy, istouch)
end

function love.textinput(text)
	loveframes.textinput(text)
end

function love.quit()
end

--[[
function love.resize(w, h)
	return
end
--]]