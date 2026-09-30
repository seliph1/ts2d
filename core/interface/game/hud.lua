local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)
--health ui---------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
local hud_nums = love.graphics.newImageFont("gfx/hud_nums.png", "0123456789:|", 10)
local hud_symbols = LF.CreateSpriteSheet("gfx/hud_symbols.bmp", 64, 64)

ui.hud = LF.Create("container")
ui.hud:SetSize(1, 0.15):AlignBottom()
ui.hud:SetState("game")
ui.hud:SetProperty("counter", 0)
ui.hud:SetCollidable(false)

function ui.hud:Draw()
	if not client.share.players then return end
	if not client.share.players[client.id] then return end

	local game = client.share.game
	if not (game and game.timer and game.timer_start) then return end
	local timer_now = os.time() - game.timer_start
	if game.paused == true then
		timer_now = game.pause_start - game.timer_start
	end
	local timer = math.max(0, game.timer - timer_now)
	local time = os.date("%M:%S", math.floor(timer)) or ""

	local player = client.share.players[client.id]
	if player.h <= 0 then return end

	local health = tostring(player.h or 0)
	local money = tostring(player.m or 0)
	local ammo = ""

	self.counter = self.counter + 1
	if player.i then
		local itemheld, itemdata = client.get_item_held(client.id)

		local itemobject = player.i[itemheld]
		if itemobject then
			local ammo_mag = itemobject.am or 0
			local ammo_cap = itemobject.ac or 0

			if ammo_cap and ammo_mag then
				ammo = string.format("%s|%s", ammo_mag, ammo_cap)
			end
		end
	end

	love.graphics.push()
	love.graphics.translate(self.x, self.y)

	local scale = 0.6
	local icon_width = hud_symbols[0]:getWidth() * scale
	local icon_height = hud_symbols[0]:getHeight() * scale
	local padding = icon_width + 5
	local money_width = hud_nums:getWidth(money)
	local ammo_width = hud_nums:getWidth(ammo)
	local width, height = self.width, self.height

	local prev_font = love.graphics.getFont()
	love.graphics.setFont(hud_nums)
	love.graphics.setBlendMode("add")
	love.graphics.setColor(1.0, 1.0, 0.0, 0.3)

	love.graphics.draw(hud_symbols[0], 0, height * 0.5, 0, scale, scale)
	love.graphics.print(health, padding, height * 0.5, 0, scale, scale)

	love.graphics.draw(hud_symbols[2], width * 0.3, height * 0.5, 0, scale, scale)
	if timer < 30 then
		love.graphics.setColor(1.0, 0.0, 0.0, 0.3)
		love.graphics.print(time, width * 0.3 + padding, height * 0.5, 0, scale, scale)
		love.graphics.setColor(1.0, 1.0, 0.0, 0.3)
	else
		love.graphics.print(time, width * 0.3 + padding, height * 0.5, 0, scale, scale)
	end
	love.graphics.draw(hud_symbols[7], width - money_width * scale - padding, height * 0, 0, scale, scale)
	love.graphics.printf(money, (1 - scale) * width, height * 0, width, "right", 0, scale, scale)


	love.graphics.printf(ammo, (1 - scale) * width, height * 0.5, width, "right", 0, scale, scale)

	love.graphics.setFont(prev_font)
	love.graphics.setBlendMode("alpha")
	love.graphics.pop()
end


end
