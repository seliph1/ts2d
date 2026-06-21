--- Cena: Editor (editor de mapas)
--- Ativada por client.scene.switch("editor"). A UI do editor vive em
--- core/interface/editor.lua; coloque aqui a lógica de ENTRAR/SAIR do editor.
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
