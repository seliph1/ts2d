loveframes = require "lib/loveframes"
client = require "client"
console = require "interface/console"
--require "lib/lovedebug"


function love.load()
	love.graphics.setBackgroundColor(1,1,1,1)
	
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

function love.mousepressed(x, y, button)
	client.mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	client.mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function love.keypressed(key, unicode)
	
	if (key == "escape") then os.exit(0) end
	if (key=="f1") then
		local state = loveframes.config["DEBUG"]
		loveframes.config["DEBUG"] = not state
	end
	
	client.keypressed(key, unicode)
	loveframes.keypressed(key, unicode)
end

function love.keyreleased(key, unicode)
	client.keyreleased(key, unicode)
	loveframes.keyreleased(key)
end

function love.mousemoved( x, y, dx, dy, istouch )
	client.mousemoved(x, y, dx, dy, istouch)
end

function love.textinput(text)
	loveframes.textinput(text)
end

--[[
function love.resize(w, h)
	return
end
--]]

