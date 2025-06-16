local loveframes = require "lib/loveframes"
local console = require "console"
local server = require "server"

function love.load()
	server.load()
	server.start("127.0.0.1","36963")
end

function love.update( dt )
	loveframes.update(dt)
	server.update(dt)
end

function love.draw()
	loveframes.draw()
end 

function love.mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function love.keypressed(key, unicode)
	
	if (key == "escape") then os.exit(0) end
	if (key=="f1") then
		local state = loveframes.config["DEBUG"]
		loveframes.config["DEBUG"] = not state
	end
	
	
	loveframes.keypressed(key, unicode)
end

function love.keyreleased(key, unicode)
	loveframes.keyreleased(key)
end

function love.textinput(text)
	loveframes.textinput(text)
end