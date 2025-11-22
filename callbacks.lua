return function(client)
---------- module start ----------

local home = client.home
--------------------------------------------------------------------------------------------------
--love callbacks----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
function client.resize(w, h)
	home.screenw = w
	home.screenh = h
end

--- Client loading routine at the start of program
function client.load()
	-- Set up initial values for client
	home.screenh = love.graphics.getWidth()
	home.screenw = love.graphics.getHeight()
	home.attack = false
	home.attack2 = false
	home.attack3 = false
end

--- Callback for mouse movement on screen
---@param x number
---@param y number
function client.mousemoved(x, y)
    -- Transform mouse coordinates according to display centering and scaling
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	local rel_x = x - (w - client.width)/2
	local rel_y = y - (h - client.height)/2
	-- Dont go less than 0 or more than 600/800 even if mouse is out of bounds
	local abs_x = math.min(math.max(rel_x, 0), client.width)
	local abs_y = math.min(math.max(rel_y, 0), client.height)
	-- Update mouse position
	home.targetX = abs_x
	home.targetY = abs_y
end

--- Callback for mouse clicking on screen
---@param x number
---@param y number
---@param button number
function client.mousepressed(x, y, button, istouch, presses)
	if not client.key[button] then
		client.sendInput(button, true)
	end
	client.key[button] = true
	----------------------------------------------------------------
	local mx, my = client.map:mouseToMap(love.mouse.getPosition())
end

--- Callback for mouse button releasing on screen
---@param x number
---@param y number
---@param button number
function client.mousereleased(x, y, button, istouch, presses)
	if client.key[button] then
		client.sendInput(button, nil)
	end
	client.key[button] = nil
	----------------------------------------------------------------

	if button == 2 then
		local tx, ty = client.map:mouseToMap(x, y)
	end
end

function client.wheelmoved(x, y)
	local button
	if y == 1 then
		button = "mwheelup"
	elseif y == - 1 then
		button = "mwheeldown"
	end
	client.sendInput(button, true)
end

--- Callback for key press event
---@param key string Key pressed
function client.keypressed(key)
	if not client.key[key] then
		client.sendInput(key, true)
	end
	client.key[key] = true
end

--- Callback for key release event
---@param key string Key released
function client.keyreleased(key)
	if client.key[key] then
		client.sendInput(key, nil)
	end
	client.key[key] = nil
end

function client.frame(dt)
	if client.joined then
		client.snapshot_lerp(dt)
	end
end

---Main game loop
---@param dt number
function client.update(dt)
	client.preupdate(dt)
	if (client.mode == "game" or client.mode == "editor") and client.map then
		client.camera_move(dt)
		client.camera_tween(dt)
		client.map:scroll(client.camera.x, client.camera.y)
		client.map:update(dt)
	end

	client.frame(dt)
	client.postupdate(dt)

	-- Update visual effects on client after data transfer take effect
	if (client.mode == "game" or client.mode == "editor") and client.map then
		client.render()
	end
end

---Main game render loop
function client.draw()
	-- Draw background if it's in lobby mode
	if client.mode == "lobby" then
		client.draw_splash(0, 0)
	end

	if client.mode == "game" or client.mode == "editor" then
		-- Center and scale display
		local ox = 0.5 * (love.graphics.getWidth() - client.width)
		local oy = 0.5 * (love.graphics.getHeight() - client.height)

		if client.scale then
			love.graphics.push()
			love.graphics.setDefaultFilter("linear", "linear")
			love.graphics.scale(love.graphics.getWidth() / client.width, love.graphics.getHeight() / client.height)
			love.graphics.draw(client.canvas, -ox, -oy)
			love.graphics.pop()
		else
			love.graphics.draw(client.canvas, 0, 0)
		end
	end

	-- Crosshair debug
	if client.debug_level > 0 then
		-- Draw middle crosshair
		love.graphics.line(love.graphics.getWidth()/2-5, love.graphics.getHeight()/2, love.graphics.getWidth()/2+5, love.graphics.getHeight()/2)
		love.graphics.line(love.graphics.getWidth()/2, love.graphics.getHeight()/2-5, love.graphics.getWidth()/2, love.graphics.getHeight()/2+5)
	end

	if client.debug_level == 2 then
		-- Advanced debug
		local x = client.camera.x or 0
		local y = client.camera.y or 0
		local ping = client.getPing() or 0
		local fps = love.timer.getFPS()
		local targetX = client.mouse.x or 0
		local targetY = client.mouse.y or 0
		local memory = (collectgarbage "count" / 1024) or 0
		local pendingInputs = client.inputCache:count() or 0

		local label = string.format("Camera: %dpx|%dpx  Ping: %s  FPS: %s  Target: %d|%d   Memory: %.2f MB  Pending Inputs: %s",
			x, y, ping, fps, targetX, targetY, memory, pendingInputs
		)

		love.graphics.printf(label, 0, love.graphics.getHeight()-20, love.graphics.getWidth(), "center")
	elseif client.debug_level == 1 then
		local memory = string.format("%.4f", collectgarbage("count") / 1024 )
		local fps = love.timer.getFPS()

		love.graphics.print(love.timer.getFPS(), love.graphics.getWidth()/2, 20)
		love.graphics.print(memory, love.graphics.getWidth()/2, 40)
	else
		-- void
	end
end


---------- module end ------------
end