--- Cena: Editor (editor de mapas)
--- Encapsula o ciclo de simulação e renderização do editor de mapas.
return {
	---@param client table
	---@param from string?
	enter = function(client, from)
		local loveframes = package.loaded["lib.loveframes"]
		if loveframes and loveframes.SetState then
			loveframes.SetState("editor")
		end
		loveframes.SetKeyNavigation(false)
	end,

	---@param client table
	---@param to string?
	exit = function(client, to)
		local loveframes = package.loaded["lib.loveframes"]
		if loveframes and loveframes.SetKeyNavigation then
			loveframes.SetKeyNavigation(true)
		end
		-- Ao sair da cena do editor, oculta o inspetor e limpa a entidade selecionada
		local ok, editor = pcall(require, "core.interface.editor")
		if ok and editor and editor.close_inspector then
			editor.close_inspector()
		end
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

	--- Manipula cliques do mouse na cena do editor
	---@param client table
	---@param x number
	---@param y number
	---@param button number
	mousepressed = function(client, x, y, button, istouch, presses)
		-- Botão esquerdo: verifica seleção de entidade no mapa e abre/atualiza o inspetor
		if button == 1 then
			local ok, editor = pcall(require, "core.interface.editor")
			if ok and editor and editor.mousepressed then
				return editor.mousepressed(client, x, y, button, istouch, presses)
			end
		end
		return false
	end,

	---@param client table
	draw = function(client)
		love.graphics.push('all')
		love.graphics.setCanvas(client.canvas)
		love.graphics.clear()

		local ox = 0.5 * (love.graphics.getWidth() - client.width)
		local oy = 0.5 * (love.graphics.getHeight() - client.height)

		-- Renderiza camadas do mapa no modo editor
		if client.map then
			client.map:draw_floor()
			client.map:draw_entities(client)
			client.map:draw_ceiling()
			client.map:draw_shadow()
			client.map:draw_effects()
			client.map:draw_entity_icons(client)

			-- Desenha a caixa de seleção animada ciano ao redor da entidade selecionada
			local ok, editor = pcall(require, "core.interface.editor")
			if ok and editor and editor.draw_selection then
				editor.draw_selection(client)
			end
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
