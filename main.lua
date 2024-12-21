function love.load()
	loveframes = require "loveframes"
	--loveframes.config["DEBUG"]=true
	loveframes.SetActiveSkin("CS2D")
	
	--love.filesystem.load("interface/init.lua")()
	love.filesystem.load("cs2dmap.lua")()
end

function love.update( dt )

	mapdata_update(dt)
	loveframes.update(dt)
	
	love.window.setTitle(love.timer.getFPS())
end

function love.draw()
	--love.graphics.setBackgroundColor(0, 0, 0, 0)
	
	mapdata_draw()
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
	
	mapdata_keypressed(key, unicode)
	loveframes.keypressed(key, unicode)
end

function love.keyreleased(key, unicode)

	mapdata_keyreleased(key, unicode)
	loveframes.keyreleased(key)
end

function love.textinput(text)
	loveframes.textinput(text)
end
