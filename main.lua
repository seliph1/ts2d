function love.load()
	loveframes = require "loveframes"
	--loveframes.config["DEBUG"]=true
	loveframes.SetActiveSkin("CS2D")
	
	love.filesystem.load("shader/cs2dshaders.lua")()
	love.filesystem.load("cs2dmap.lua")()
	love.filesystem.load("interface/editor.lua")()

	
	global_key_pressed = {}
	cam_x, cam_y = 0, 0
	mouse_x, mouse_y = 0, 0
end

function love.update( dt )
	

	if loveframes.GetCollisionCount() == 0 then
		local s = 500*dt
		if (global_key_pressed.up) then cam_y = cam_y - s end
		if (global_key_pressed.down) then cam_y = cam_y + s end
		if (global_key_pressed.left) then cam_x = cam_x - s end
		if (global_key_pressed.right) then cam_x = cam_x + s end
	end
	
	mouse_x = math.floor( (love.mouse.getX() - love.graphics.getWidth()/2 + cam_x) / 32  )
	mouse_y = math.floor( (love.mouse.getY() - love.graphics.getHeight()/2 + cam_y) / 32  )
	
	--love.window.setTitle (love.timer.getFPS( ))
	
	loveframes.update(dt)
end

function love.draw()
	--love.graphics.setBackgroundColor(0, 0, 0, 0)
	
	mapdata_draw(cam_x, cam_y)
	
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

	loveframes.keypressed(key, unicode)
end

function love.keyreleased(key, unicode)
	global_key_pressed[key] = nil
	
	loveframes.keyreleased(key)
end

function love.textinput(text)
	loveframes.textinput(text)
end
