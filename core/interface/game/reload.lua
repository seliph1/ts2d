local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)
--reload window-----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
function ui.reload_display(seconds)
	if ui.reload_window or not (client.joined) then return end
	seconds = seconds or 3.5

	ui.reload_window = LF.Create("panel")
		:SetCollidable(false)
		:SetSize(100, 19)
		:CenterX()
		:SetY(0.4)
		:SetProperty("margin", 2)
		:SetProperty("line_width", 1)
		:SetProperty("font_height", ui.font_small:getHeight())
		:SetProperty("font", ui.font_small)
		:SetProperty("time_start", love.timer.getTime())
		:SetProperty("progress", 0)
		:SetProperty("progress_max", seconds)

	function ui.reload_window:Draw()
		love.graphics.push()
		-- Change coordinate origin
		love.graphics.translate(self.x, self.y)

		-- Color and blend mode (to make it semi transparent)
		love.graphics.setColor(0.72, 0.72, 0.00, 1.00)
		love.graphics.setBlendMode("add")

		-- Font and line width
		love.graphics.setFont(self.font)
		love.graphics.setLineWidth(self.line_width)

		-- "Reloading" label
		love.graphics.printf("Reloading", 0, -(self.font_height + 1), self.width, "center")

		-- Outline
		love.graphics.rectangle(
			"line",
			0,
			0,
			self.width,
			self.height
		)

		-- Calculate time progress
		self.progress = love.timer.getTime() - self.time_start

		-- Calculate line fill
		local line_progress =
			math.min(1, self.progress / self.progress_max)
			* (self.width - self.margin * 2)
			+ (self.margin * 2)

		-- Fill
		love.graphics.rectangle(
			"fill",
			self.margin,
			self.margin,
			line_progress - self.margin * 2,
			self.height - self.margin * 2
		)

		-- Reset graphic settings
		love.graphics.pop()
		love.graphics.setBlendMode("alpha")
		love.graphics.setColor(1.00, 1.00, 1.00, 1.00)
	end
end

function ui.reload_dispose()
	if ui.reload_window then
		ui.reload_window:Remove()
		ui.reload_window = nil
	end
end

end
