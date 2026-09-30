local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)
--spectator controls------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
ui.spec_control = LF.Create("panel")
	:SetState("game")
	:SetSize(1, 0.07)
	:AlignBottom()
	:SetAlwaysUpdate(true)
	:SetCollidable(false)

function ui.spec_control:Update()
	if not client.share.players then return end
	if not client.share.players[client.id] then return end
	local player = client.share.players[client.id]

	local should_show = (player.h <= 0)
	if self.visible ~= should_show then
		self:SetVisible(should_show)
		client.parse(should_show and "camera unbind" or "camera self")
	end
end

function ui.spec_control:Draw()
	local opacity = 0.2
	love.graphics.setColor(0.0, 0.0, 0.0, opacity)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

ui.spec_control_menu = LF.Create("button", ui.spec_control)
	:SetSize(0.06, 0.8)
	:SetText("Menu")

ui.spec_control_map = LF.Create("button", ui.spec_control)
	:SetSize(0.06, 0.8)
	:SetText("Map")

ui.spec_control_fog = LF.Create("button", ui.spec_control)
	:SetSize(0.06, 0.8)
	:SetText("Fog")

ui.spec_control_player = LF.Create("button", ui.spec_control)
	:SetSize(0.58, 0.8)
	:SetText("-")

ui.spec_control_mode = LF.Create("button", ui.spec_control)
	:SetSize(0.18, 0.8)
	:SetText("Free Look")

ui.spec_control:Spread("horizontal"):AlignChildren("horizontal")


end
