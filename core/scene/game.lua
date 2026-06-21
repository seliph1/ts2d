--- Cena: Game (gameplay)
--- Ativada por client.scene.switch("game"). O loop de simulação/render do jogo hoje
--- vive em client.update/client.draw (core/game/callbacks.lua) e em client.render();
--- coloque aqui a lógica de ENTRAR/SAIR da partida (ex.: travar input do menu).
return {
	---@param client table
	---@param from string?
	enter = function(client, from)
	end,

	---@param client table
	---@param to string?
	exit = function(client, to)
	end,

	-- update = function(client, dt) end,
	-- draw   = function(client) end,
}
