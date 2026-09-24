local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)
--buy menu----------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
function ui.buymenu_display()
	if ui.buymenu or not (client.joined) then return end

	local share = client.share
	if not (share or share.players or share.config) then return end

	local players = share.players
	if not players then return end

	local player = share.players[client.id]
	if not player then return end
	if player.h < 0 or player.t == 0 then return end -- Spec or dead

	local shop = share.config.shop
	if not shop then return end

	ui.buymenu = LF.Create("frame")
		:SetName("Buy")
		:SetSize(0.8, 0.8)
		:Center()

	function ui.buymenu:OnClose()
		ui.buymenu = nil
	end

	local list = LF.Create("scrollpanel", ui.buymenu)
		:SetPos(0, 35)
		:Expand("down", 5)
		:Expand("right", 0.5)

	local display = LF.Create("panel", ui.buymenu)
		--:SetBackground(true)
		:SetPos(0.5, 35)
		:Expand("down", 35)
		:Expand("right", 5)

	function display:DrawOver()
		love.graphics.push()
		love.graphics.translate(self:GetPos())
		local hoverobject = LF.GetHoverObject()
		if hoverobject
			and hoverobject.type == "button"
			and hoverobject.item_type
		then
			local text = hoverobject:GetText()
			local item_type = hoverobject:GetProperty("item_type")
			if item_type then
				local itemdata = client.get_item_data(item_type)
				if itemdata.display_image then
					local path = itemdata.common_path .. itemdata.display_image
					local gfx = client.map:getImage(path)
					local width = gfx:getWidth() / 2
					local scale = 4
					local timer = love.timer.getTime()
					local oscillator = math.sin(timer)
					local floater = math.sin(timer * 3)

					gfx:setFilter("nearest", "nearest")
					love.graphics.draw(gfx, self.width / 2, 50, 0, oscillator * scale, 1 * scale, width, floater * 3, 0,
						0)
				end

				local padding = 10
				local height = 240
				love.graphics.setFont(ui.font_chat)
				if itemdata.category == "primary" or itemdata.category == "secondary" then
					love.graphics.setColor(1, 1, 1, 1)
					love.graphics.print(itemdata.name, padding, height)
					love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
					love.graphics.print("Price: " .. itemdata.price, padding, height + 20)
					love.graphics.print("Damage: " .. itemdata.damage, padding, height + 40)
					love.graphics.print("Ammo: " .. itemdata.ammo_mag .. "/" .. itemdata.ammo_cap, padding, height + 60)
					love.graphics.print("Rate of Fire: " .. itemdata.frame_delay, padding, height + 80)
					love.graphics.print("Range: " .. itemdata.range, padding, height + 100)
					love.graphics.print("Weight: " .. itemdata.weight, padding, height + 120)
					love.graphics.print("Accuracy: " .. itemdata.accuracy, padding, height + 140)
				else
					love.graphics.setColor(1, 1, 1, 1)
					love.graphics.print(itemdata.name, padding, height)
				end
			end
		end

		love.graphics.pop()
	end

	function ui.buymenu.list_category(category)
		local counter = 0
		if not category.items then return end

		list:Clear()
		local teamitems = category.teamitems or {}

		for index, item_type in ipairs(category.items) do
			local itemdata = client.get_item_data(item_type)
			local item_team = teamitems[item_type]
			local self_team = player.t
			local price = itemdata.price

			if shop.price_override and shop.price_override[item_type] then
				price = shop.price_override[item_type]
			end

			if (not item_team) or (item_team == self_team) then
				local button = LF.Create("button", list)
					:SetAlign("left")
					:SetImageAlign("center")
					:SetText(" " .. (itemdata.name or "Unknown"))
					:SetCaption("$ " .. tostring(price))
					:SetPos(5, counter * 32)
					:Expand("right", 5)
					:SetHeight(28)
					:SetPadding(60)
					:SetImagePadding(30)
					:SetProperty("item_type", item_type)

				if itemdata.kill_image ~= "" then
					button:SetImage(
					--itemdata.common_path .. itemdata.kill_image
						itemdata.common_path .. itemdata.dropped_image
					)
				end

				function button:OnClick()
					client.send("buy " .. item_type)
					ui.buymenu:Remove()
					ui.buymenu = nil
				end

				counter = counter + 1
			end
		end

		local backbutton = LF.Create("button", list)
			:SetAlign("left")
			:SetText("Back")
			:SetPos(5, (counter + 1) * 32)
			:Expand("right", 5)
			:SetHeight(28)
		function backbutton:OnClick()
			ui.buymenu.list_shop()
		end
	end

	function ui.buymenu.list_shop()
		list:Clear()
		for i = 1, #shop do
			local category = shop[i]
			if type(category) == "table" then
				local button = LF.Create("button", list)
					:SetAlign("left")
					:SetImageAlign("center")
					:SetText(category.name or "Undefined")
					:SetPos(5, (i - 1) * 32)
					:Expand("right", 5)
					:SetHeight(28)
					:SetPadding(60)
					:SetImagePadding(30)

				-- Check if the picture provided by the server exists
				-- On our computer
				if category.icon and category.icon ~= "" then
					local path = "gfx/" .. category.icon
					local file = love.filesystem.getInfo(path)
					if file and file.type == "file" then
						local icon = love.graphics.newImage(path)
						button:SetImage(icon)
					end
				end

				if type(category.items) == "table" then
					-- Void
				elseif type(category.items) == "number" then
					local item_type = category.items

					local itemdata = client.get_item_data(item_type)
					local price = itemdata.price
					if shop.price_override and shop.price_override[item_type] then
						price = shop.price_override[item_type]
					end
					if itemdata then
						button
							:SetText(" " .. (itemdata.name or "Unknown"))
							:SetCaption("$ " .. tostring(price))
							:SetProperty("item_type", item_type)
					end
				end

				function button:OnClick()
					-- Open category
					if type(category.items) == "table" then
						ui.buymenu.list_category(category)
					elseif type(category.items) == "number" then -- Else buy it directly
						local item_type = category.items
						client.send("buy " .. item_type)
						ui.buymenu:Remove()
						ui.buymenu = nil
					end
				end
			end
		end
	end

	ui.buymenu.list_shop()
end

end
