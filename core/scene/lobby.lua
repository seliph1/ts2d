--- Cena: Lobby (menu principal)
--- Gerencia o ciclo de vida e a renderização do menu principal do jogo.
local function draw_splash(client, ox, oy)
	ox = ox or 0
	oy = oy or 0
	if client.gfx and client.gfx.ui then
		local splash_art = client.gfx.ui["gfx/splash.bmp"]
		if splash_art then
			local splash_width = love.graphics.getWidth() / splash_art:getWidth()
			local splash_height = love.graphics.getHeight() / splash_art:getHeight()
			love.graphics.draw(splash_art, ox, oy, 0, splash_width, splash_height)
		end
	end
end

return {
	---@param client table
	---@param from string?
	enter = function(client, from)
		local loveframes = package.loaded["lib.loveframes"]
		if loveframes and loveframes.SetState then
			loveframes.SetState("none")
		end
	end,

	---@param client table
	---@param to string?
	exit = function(client, to)
	end,

	---@param client table
	---@param dt number
	update = function(client, dt)
	end,

	---@param client table
	draw = function(client)
		draw_splash(client, 0, 0)
	end,
}
