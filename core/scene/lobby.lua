--- Cena: Lobby (menu principal)
--- Ativada por client.scene.switch("lobby"). A renderização do menu hoje vive em
--- core/interface/ui.lua e o splash em client.draw(); coloque aqui apenas a lógica
--- que deve rodar ao ENTRAR/SAIR do menu (ex.: resetar UI, parar música de jogo).
return {
	---@param client table
	---@param from string?  cena de onde veio
	enter = function(client, from)
	end,

	---@param client table
	---@param to string?  cena para onde vai
	exit = function(client, to)
	end,

	-- update = function(client, dt) end,   -- chamado por client.scene.update(dt)
	-- draw   = function(client) end,        -- chamado por client.scene.draw()
}
