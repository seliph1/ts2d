local LF = require "lib.loveframes"

return function(ui)
--server log--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

ui.server_log = LF.Create("log")
	:SetSize(0.2, 0.1)
	:SetPos(0.8, 0)
	:SetPadding(0)
	:SetFont(ui.font_small)
	:SetScrollBody(false)
	:SetState("game")

ui.server_log_push = function(message)
	ui.server_log:AddElement(message)
end

function ui.server_log:Draw()
	local hovertime = 0
	if self.hover then
		hovertime = self:GetHoverTime()
	end
	local brightness = LF.Clamp(hovertime * 5.0, 0.3, 1.0)

	love.graphics.setColor(1, 1, 1, brightness)
	local x, y = self:GetPos()
	local offsetx = self.offsetx
	local offsety = self.offsety
	local text = self.texthash
	-- Retrieve the cell size
	local fx = math.floor(x - offsetx)
	local fy = math.floor(y - offsety)
	local skin = self:GetSkin()
	local color = skin.directives.text_default_shadowcolor
	love.graphics.setColor(
		color[1],
		color[2],
		color[3],
		brightness
	)
	love.graphics.draw(text, fx + 1, fy + 1)
	love.graphics.setColor(1, 1, 1, brightness)
	love.graphics.draw(text, fx, fy)
end


end
