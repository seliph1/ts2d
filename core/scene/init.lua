--- Scene manager
--- Centraliza as transições entre as 3 cenas do jogo: "lobby", "game" e "editor".
---
--- Envolve (não substitui) o campo `client.mode`, que continua sendo a fonte de
--- verdade lida pelo restante do código (client.update/draw, etc.). A diferença é
--- que agora toda troca passa por `client.scene.switch(name)`, um único ponto onde
--- disparamos os hooks `exit` (cena anterior) e `enter` (cena nova).
---
--- Cada cena é um módulo em core/scene/<nome>.lua que retorna uma tabela com hooks
--- opcionais: { enter(client, from), exit(client, to), update(client, dt), draw(client) }.
return function(client)
	local scene = { current = nil, scenes = {} }

	--- Registra a definição de uma cena.
	---@param name string
	---@param def table
	function scene.register(name, def)
		scene.scenes[name] = def
	end

	--- Retorna a cena ativa atual.
	---@return string?
	function scene.get_current()
		return scene.current
	end

	--- Verifica se a cena informada é a atual.
	---@param name string
	---@return boolean
	function scene.is(name)
		return scene.current == name
	end

	local STATE_MAP = {
		lobby  = "none",
		game   = "game",
		editor = "editor",
	}

	--- Troca de cena: atualiza client.mode e dispara exit() da anterior + enter() da nova.
	--- Idempotente: trocar para a cena já ativa não refaz os hooks.
	---@param name string  "lobby" | "game" | "editor"
	function scene.switch(name, ...)
		if client.mode == name and scene.current then return end

		local prev = scene.scenes[scene.current]
		if prev and prev.exit then prev.exit(client, name) end

		client.mode   = name   -- mantém o campo legado autoritativo
		scene.current = name

		-- Sincroniza o estado do LoveFrames para mostrar apenas a UI correspondente à cena
		local loveframes = package.loaded["lib.loveframes"]
		if loveframes and loveframes.SetState then
			local lf_state = STATE_MAP[name] or "none"
			loveframes.SetState(lf_state)
		end

		if client.debug_level and client.debug_level > 0 then
			print(("scene: -> %s"):format(name))
		end

		local nx = scene.scenes[name]
		if nx and nx.enter then nx.enter(client, ...) end
	end

	--- Encaminha o update da cena ativa (no-op se a cena não define `update`).
	---@param dt number
	function scene.update(dt)
		local s = scene.scenes[scene.current]
		if s and s.update then s.update(client, dt) end
	end

	--- Encaminha o draw da cena ativa (no-op se a cena não define `draw`).
	function scene.draw()
		local s = scene.scenes[scene.current]
		if s and s.draw then s.draw(client) end
	end

	client.scene = scene

	-- Registro das cenas do projeto.
	scene.register("lobby",  require "core.scene.lobby")
	scene.register("game",   require "core.scene.game")
	scene.register("editor", require "core.scene.editor")
end
