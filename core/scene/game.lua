--- Cena: Game (gameplay)
--- Encapsula o ciclo de simulação e renderização da partida.
return {
	---@param client table
	---@param from string?
	enter = function(client, from)
		local loveframes = package.loaded["lib.loveframes"]
		if loveframes and loveframes.SetState then
			loveframes.SetState("game")
		end
	end,

	---@param client table
	---@param to string?
	exit = function(client, to)
	end,

	---@param client table
	---@param dt number
	update = function(client, dt)
		if client.map then
			client.camera_move(dt)
			client.camera_tween(dt)
			client.map:scroll(client.camera.x, client.camera.y)
			client.map:update(dt)
		end
	end,

	---@param client table
	draw = function(client)
		love.graphics.push('all')
		love.graphics.setCanvas(client.canvas)
		love.graphics.clear()

		local ox = 0.5 * (love.graphics.getWidth() - client.width)
		local oy = 0.5 * (love.graphics.getHeight() - client.height)

		-- Renderiza todas as camadas do mundo de jogo
		if client.map then
			client.map:draw_floor()
			client.map:draw_entities(client)
		end

		if client.joined and client.map then
			client.map:draw_items(client)
			client.map:draw_players(client)
		end

		if client.map then
			client.map:draw_ceiling()
			client.map:draw_effects()
			client.map:draw_hrc(ox, oy, client.width, client.height)
		end

		love.graphics.setCanvas()
		love.graphics.pop()

		-- Aplica shaders e renderiza o canvas na tela
		if client.shader then
			love.graphics.setShader(client.shader)
			if client.shader:hasUniform("time") then
				client.shader:send("time", love.timer.getTime())
			end

			if client.shader:hasUniform("mouse") then
				client.mouse = client.mouse or {}
				client.mouse[1], client.mouse[2] = love.mouse.getPosition()
				client.mouse[3] = love.mouse.isDown(1) and 1 or 0
				client.mouse[4] = love.mouse.isDown(2) and 1 or 0
				client.shader:send("mouse", client.mouse)
			end
		end

		if client.scale then
			love.graphics.push()
			love.graphics.setDefaultFilter("linear", "linear")
			love.graphics.scale(love.graphics.getWidth() / client.width, love.graphics.getHeight() / client.height)
			love.graphics.draw(client.canvas, -ox, -oy)
			love.graphics.pop()
		else
			love.graphics.draw(client.canvas, 0, 0)
		end

		if client.shader then
			love.graphics.setShader()
		end
	end,
}
