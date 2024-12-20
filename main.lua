function love.load()
	loveframes = require "loveframes"
	--loveframes.config["DEBUG"]=true
	
	loveframes.SetActiveSkin("CS2D")
	love.filesystem.load("cs2dmap.lua")()
	
	global_key_pressed = {}
end

function love.update( dt )

	mapdata_update(dt)
	loveframes.update(dt)
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
	global_key_pressed[key] = true 
	if (key == "escape") then os.exit(0) end
	if (key=="f1") then
		local state = loveframes.config["DEBUG"]
		loveframes.config["DEBUG"] = not state
	end
	
	if (key=="f2") then
		mapfile_read("maps/fun_roleplay.map")
	end

	loveframes.keypressed(key, unicode)
end

function love.keyreleased(key, unicode)
	global_key_pressed[key] = nil
	
	loveframes.keyreleased(key)
end

function love.textinput(text)
	loveframes.textinput(text)
end
