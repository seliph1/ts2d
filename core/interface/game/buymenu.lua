local LF = require "lib.loveframes"
local client = require "core.client"

return function(ui)
	-- Cache for weapon and category icons
	local image_cache = {}

	local function get_image(path)
		if not path or path == "" then return nil end
		if image_cache[path] then return image_cache[path] end

		if client.map and client.map.getImage then
			local img = client.map:getImage(path)
			if img then
				image_cache[path] = img
				return img
			end
		end

		if love.filesystem.getInfo(path) then
			local img = love.graphics.newImage(path)
			image_cache[path] = img
			return img
		end

		return nil
	end

	client.last_bought_items = client.last_bought_items or {}

	function ui.buymenu_display()
		if ui.buymenu or not (client.joined) then return end

		local share = client.share
		if not (share or share.players or share.config) then return end

		local players = share.players
		if not players then return end

		local player = players[client.id]
		if not player then return end
		if player.h < 0 or player.t == 0 then return end -- Spectator or dead

		local shop = share.config.shop
		if not shop then return end

		local screen_w = love.graphics.getWidth()
		local screen_h = love.graphics.getHeight()
		local menu_w = math.min(840, math.floor(screen_w * 0.90))
		local menu_h = math.min(580, math.floor(screen_h * 0.90))

		ui.buymenu = LF.Create("frame")
			:SetName("Buy Menu")
			:SetSize(menu_w, menu_h)
			:Center()

		function ui.buymenu:OnClose()
			ui.buymenu = nil
		end

		-- Layout: Left side (~60%) for card grid and actions; Right side for details
		local left_w = math.floor(menu_w * 0.60)
		local right_w = menu_w - left_w - 25

		-- Scrollable Card Grid Container (uses skin.scrollpanel natively)
		local card_grid = LF.Create("scrollpanel", ui.buymenu)
			:SetPos(10, 32)
			:SetSize(left_w, 350)

		-- Right Details Panel (uses skin.panel natively)
		local details_panel = LF.Create("panel", ui.buymenu)
			:SetPos(left_w + 15, 32)
			:SetSize(right_w, menu_h - 42)

		-- State variables
		local current_category = nil
		local selected_item_data = nil
		local selected_category_data = nil
		local active_cards = {}
		local close_button = nil

		-- DrawOver for Details Panel: draws preview box, floating sprite and stat bars on top of skin.panel
		function details_panel:DrawOver()
			local x, y = self:GetPos()
			local w, h = self:GetSize()

			local itemdata = selected_item_data

			-- If no item is hovered but a category is selected/hovered:
			if not itemdata and selected_category_data then
				local cat = selected_category_data
				local preview_h = 130
				love.graphics.setColor(0.07, 0.08, 0.10, 0.7)
				love.graphics.rectangle("fill", x + 10, y + 10, w - 20, preview_h, 6, 6)
				love.graphics.setColor(0.22, 0.24, 0.28, 0.6)
				love.graphics.rectangle("line", x + 10, y + 10, w - 20, preview_h, 6, 6)

				if cat.icon and cat.icon ~= "" then
					local icon_path = cat.icon:match("^gfx/") and cat.icon or ("gfx/" .. cat.icon)
					local icon = get_image(icon_path)
					if icon then
						icon:setFilter("nearest", "nearest")
						local timer = love.timer.getTime()
						local floater = math.sin(timer * 2.5) * 4
						local iw, ih = icon:getWidth(), icon:getHeight()
						local scale = math.min(160 / iw, 80 / ih, 3.5)
						love.graphics.setColor(1, 1, 1, 1)
						love.graphics.draw(icon, x + w / 2, y + 10 + preview_h / 2 + floater, 0, scale, scale, iw / 2, ih / 2)
					end
				end

				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.print(cat.name or "Category", x + 15, y + preview_h + 20)
				love.graphics.setColor(0.65, 0.70, 0.75, 1)
				if cat.count then
					love.graphics.print(tostring(cat.count) .. " available items", x + 15, y + preview_h + 40)
				end
				love.graphics.print("Click or press 1-9 to view weapons.", x + 15, y + preview_h + 65)
				love.graphics.setColor(1, 1, 1, 1)
				return
			end

			if not itemdata then
				love.graphics.setColor(0.6, 0.65, 0.7, 1)
				love.graphics.print("Hover over an item to view stats.", x + 15, y + 20)
				love.graphics.setColor(1, 1, 1, 1)
				return
			end

			-- Sprite Preview Area
			local preview_h = 130
			love.graphics.setColor(0.07, 0.08, 0.10, 0.7)
			love.graphics.rectangle("fill", x + 10, y + 10, w - 20, preview_h, 6, 6)
			love.graphics.setColor(0.22, 0.24, 0.28, 0.6)
			love.graphics.rectangle("line", x + 10, y + 10, w - 20, preview_h, 6, 6)

			-- Oscillating animated sprite
			local img_name = itemdata.display_image or itemdata.dropped_image or itemdata.held_image or ""
			local img_path = (itemdata.common_path or "gfx/weapons/") .. img_name
			local gfx = get_image(img_path)
			if gfx then
				gfx:setFilter("nearest", "nearest")
				local timer = love.timer.getTime()
				local floater = math.sin(timer * 3) * 4
				local gw, gh = gfx:getWidth(), gfx:getHeight()
				local scale = math.min(180 / gw, 80 / gh, 3.5)
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(gfx, x + w / 2, y + 10 + preview_h / 2 + floater, 0, scale, scale, gw / 2, gh / 2)
			end

			-- Weapon Name & Subtitle
			local cur_y = y + preview_h + 18
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print(itemdata.name or "Unknown Item", x + 15, cur_y)

			cur_y = cur_y + 18
			local price = itemdata.price
			if shop.price_override and itemdata.id and shop.price_override[itemdata.id] then
				price = shop.price_override[itemdata.id]
			end

			if price then
				local can_afford = (player.m or 0) >= price
				if can_afford then
					love.graphics.setColor(0.3, 0.85, 0.3, 1)
				else
					love.graphics.setColor(0.85, 0.3, 0.3, 1)
				end
				love.graphics.print("$ " .. tostring(price), x + 15, cur_y)
			end

			-- Team restriction badge
			local team_text = "All Teams"
			local team_color = { 0.6, 0.6, 0.65, 1 }
			local item_team = itemdata.team
			if not item_team and current_category and current_category.teamitems and itemdata.id then
				item_team = current_category.teamitems[itemdata.id]
			end

			if item_team == 1 then
				team_text = "Terrorist Only"
				team_color = { 0.9, 0.4, 0.3, 1 }
			elseif item_team == 2 then
				team_text = "CT Only"
				team_color = { 0.4, 0.65, 0.95, 1 }
			end

			love.graphics.setColor(team_color)
			love.graphics.print(team_text, x + 100, cur_y)

			cur_y = cur_y + 22
			love.graphics.setColor(0.25, 0.27, 0.32, 0.8)
			love.graphics.line(x + 15, cur_y, x + w - 15, cur_y)
			cur_y = cur_y + 10

			-- Helper to render clean attribute progress bars
			local function draw_stat_bar(label, value_str, ratio)
				ratio = math.max(0, math.min(1, ratio or 0))
				love.graphics.setColor(0.80, 0.82, 0.85, 1)
				love.graphics.print(label, x + 15, cur_y)

				local font = love.graphics.getFont()
				local vw = font and font:getWidth(value_str) or 30
				love.graphics.print(value_str, x + w - 15 - vw, cur_y)
				cur_y = cur_y + 16

				-- Bar track
				local bar_w = w - 30
				local bar_h = 6
				love.graphics.setColor(0.18, 0.20, 0.24, 0.9)
				love.graphics.rectangle("fill", x + 15, cur_y, bar_w, bar_h, 3, 3)

				-- Bar fill
				love.graphics.setColor(0.35, 0.65, 0.95, 0.9)
				if ratio > 0 then
					love.graphics.rectangle("fill", x + 15, cur_y, math.max(bar_w * ratio, 3), bar_h, 3, 3)
				end
				cur_y = cur_y + bar_h + 8
			end

			if itemdata.damage then
				draw_stat_bar("Damage", tostring(itemdata.damage), itemdata.damage / 100)
			end

			if itemdata.frame_delay then
				local rof_ratio = math.max(0.05, 1 - (itemdata.frame_delay - 5) / 55)
				local rpm = math.floor(3000 / math.max(1, itemdata.frame_delay))
				draw_stat_bar("Rate of Fire", rpm .. " RPM", rof_ratio)
			end

			if itemdata.accuracy ~= nil then
				draw_stat_bar("Accuracy", itemdata.accuracy .. "%", itemdata.accuracy / 100)
			end

			if itemdata.range then
				draw_stat_bar("Range", tostring(itemdata.range), itemdata.range / 400)
			end

			if itemdata.ammo_mag and itemdata.ammo_cap then
				draw_stat_bar("Ammo", itemdata.ammo_mag .. " / " .. itemdata.ammo_cap, itemdata.ammo_mag / 50)
			end

			if itemdata.weight then
				local kg = string.format("%.1f kg", itemdata.weight / 1000)
				draw_stat_bar("Weight", kg, itemdata.weight / 5000)
			end

			love.graphics.setColor(1, 1, 1, 1)
		end

		-- Buy Action
		local function buy_item(item_id)
			table.insert(client.last_bought_items, item_id)
			client.send("buy " .. item_id)
			if ui.buymenu then
				ui.buymenu:Remove()
				ui.buymenu = nil
			end
		end

		-- Auto-Buy Handler
		local function do_autobuy()
			local self_team = player.t
			if self_team == 1 then
				client.send("buy 30") -- AK-47
			elseif self_team == 2 then
				client.send("buy 32") -- M4A1
				client.send("buy 56") -- Defusal Kit
			end
			client.send("buy 57") -- Kevlar + Helmet
			client.send("buy 58") -- Kevlar
			client.send("buy 61") -- Primary ammo
			client.send("buy 62") -- Secondary ammo
			if ui.buymenu then
				ui.buymenu:Remove()
				ui.buymenu = nil
			end
		end

		-- Re-Buy Previous Handler
		local function do_rebuy()
			if client.last_bought_items and #client.last_bought_items > 0 then
				for _, id in ipairs(client.last_bought_items) do
					client.send("buy " .. id)
				end
			end
			client.send("buy 61")
			client.send("buy 62")
			if ui.buymenu then
				ui.buymenu:Remove()
				ui.buymenu = nil
			end
		end

		-- Function to create a styled card button
		-- Uses skin.button for native background, border, press offsets, and uses DrawOver ONLY for card graphics
		local function create_card(badge_num, title, icon_img, footer_text, is_price, price_val, on_click, on_hover)
			local card_w = math.floor((left_w - 40) / 3)
			local card_h = 100

			local card = LF.Create("button", card_grid)
				:SetSize(card_w, card_h)
				:SetText("")
				:Fill(10, "horizontal", 3)

			card.badge = tostring(badge_num)
			card.card_title = title
			card.card_icon = icon_img
			card.footer_text = footer_text
			card.is_price = is_price
			card.price_val = price_val

			-- DrawOver: renders custom card content on top of native skin.button
			function card:DrawOver()
				local x, y = self:GetPos()
				local w, h = self:GetSize()
				local ox, oy = 0, 0
				if self.down then
					ox, oy = 1, 1
				end

				-- Top-left Badge
				if self.badge then
					love.graphics.setColor(0.85, 0.85, 0.90, 1.0)
					love.graphics.print(self.badge, x + 8 + ox, y + 6 + oy)
				end

				-- Top Title
				if self.card_title then
					love.graphics.setColor(1, 1, 1, 1)
					local font = love.graphics.getFont()
					local tw = font and font:getWidth(self.card_title) or 60
					local tx = x + (w - tw) / 2
					love.graphics.print(self.card_title, math.max(x + 22, tx) + ox, y + 6 + oy)
				end

				-- Center Icon
				local img = self.card_icon
				if img then
					love.graphics.setColor(1, 1, 1, 1)
					img:setFilter("nearest", "nearest")
					local iw = img:getWidth()
					local ih = img:getHeight()
					local scale = math.min(65 / iw, 36 / ih, 2.5)
					love.graphics.draw(img, x + w / 2 + ox, y + h / 2 + 2 + oy, 0, scale, scale, iw / 2, ih / 2)
				end

				-- Footer
				if self.is_price and self.price_val then
					local can_afford = (player.m or 0) >= self.price_val
					if can_afford then
						love.graphics.setColor(0.3, 0.85, 0.3, 1.0)
					else
						love.graphics.setColor(0.85, 0.3, 0.3, 1.0)
					end
					local txt = "$ " .. tostring(self.price_val)
					local font = love.graphics.getFont()
					local tw = font and font:getWidth(txt) or 40
					love.graphics.print(txt, x + (w - tw) / 2 + ox, y + h - 20 + oy)
				elseif self.footer_text then
					love.graphics.setColor(0.70, 0.75, 0.80, 1.0)
					local font = love.graphics.getFont()
					local tw = font and font:getWidth(self.footer_text) or 40
					love.graphics.print(self.footer_text, x + (w - tw) / 2 + ox, y + h - 20 + oy)
				end

				love.graphics.setColor(1, 1, 1, 1)
			end

			function card:OnClick()
				if on_click then on_click() end
			end

			local old_update = card.Update
			function card:Update(dt)
				if old_update then old_update(self, dt) end
				if self.hover and on_hover then
					on_hover()
				end
			end

			return card
		end

		-- Navigation forward declaration
		local list_shop
		local list_category

		-- Display weapons inside a specific category
		list_category = function(category)
			current_category = category
			selected_category_data = nil
			card_grid:Clear()
			active_cards = {}

			if close_button then
				close_button:SetText("0 Back")
			end

			if not category.items then return end
			local teamitems = category.teamitems or {}
			local self_team = player.t

			local slot = 1
			for _, item_type in ipairs(category.items) do
				if slot > 9 then break end
				local itemdata = client.get_item_data(item_type)
				local item_team = teamitems[item_type]

				if (not item_team) or (item_team == self_team) then
					local price = itemdata.price
					if shop.price_override and shop.price_override[item_type] then
						price = shop.price_override[item_type]
					end

					local img_name = itemdata.dropped_image or itemdata.display_image or itemdata.held_image or ""
					local img_path = (itemdata.common_path or "gfx/weapons/") .. img_name
					local img = get_image(img_path)

					-- If nothing is selected, preview first weapon
					if not selected_item_data then
						selected_item_data = itemdata
						selected_item_data.id = item_type
					end

					local cur_slot = slot
					local card = create_card(
						cur_slot,
						itemdata.name or "Weapon",
						img,
						nil,
						true,
						price,
						function()
							buy_item(item_type)
						end,
						function()
							selected_item_data = itemdata
							selected_item_data.id = item_type
						end
					)

					active_cards[cur_slot] = {
						action = function()
							buy_item(item_type)
						end
					}

					slot = slot + 1
				end
			end
		end

		-- Display main category grid
		list_shop = function()
			current_category = nil
			card_grid:Clear()
			active_cards = {}

			if close_button then
				close_button:SetText("0 Close")
			end

			local slot = 1
			for i = 1, #shop do
				if slot > 9 then break end
				local category = shop[i]

				if type(category) == "table" then
					local self_team = player.t
					local teamitems = category.teamitems or {}

					if type(category.items) == "table" then
						-- Count available items for player's team
						local count = 0
						local preview_item_data = nil
						for _, item_id in ipairs(category.items) do
							local t = teamitems[item_id]
							if not t or t == self_team then
								count = count + 1
								if not preview_item_data then
									preview_item_data = client.get_item_data(item_id)
									if preview_item_data then
										preview_item_data.id = item_id
									end
								end
							end
						end

						local icon_img = nil
						if category.icon and category.icon ~= "" then
							local path = category.icon:match("^gfx/") and category.icon or ("gfx/" .. category.icon)
							icon_img = get_image(path)
						end

						local cur_slot = slot
						local cat_data = {
							name = category.name or "Category",
							icon = category.icon,
							count = count,
							items = category.items,
							teamitems = category.teamitems,
						}

						if not selected_item_data and preview_item_data then
							selected_item_data = preview_item_data
						end

						local card = create_card(
							cur_slot,
							category.name or "Category",
							icon_img,
							count .. " items",
							false,
							nil,
							function()
								list_category(category)
							end,
							function()
								selected_category_data = cat_data
								if preview_item_data then
									selected_item_data = preview_item_data
								end
							end
						)

						active_cards[cur_slot] = {
							action = function()
								list_category(category)
							end
						}

						slot = slot + 1
					elseif type(category.items) == "number" then
						-- Direct item (e.g. ammo or equipment)
						local item_id = category.items
						local itemdata = client.get_item_data(item_id)
						local price = itemdata and itemdata.price or 0
						if shop.price_override and shop.price_override[item_id] then
							price = shop.price_override[item_id]
						end

						local icon_img = nil
						if category.icon and category.icon ~= "" then
							local path = category.icon:match("^gfx/") and category.icon or ("gfx/" .. category.icon)
							icon_img = get_image(path)
						elseif itemdata then
							local img_name = itemdata.dropped_image or itemdata.display_image or ""
							icon_img = get_image((itemdata.common_path or "gfx/weapons/") .. img_name)
						end

						local cur_slot = slot
						local card = create_card(
							cur_slot,
							(itemdata and itemdata.name) or category.name or "Item",
							icon_img,
							nil,
							true,
							price,
							function()
								buy_item(item_id)
							end,
							function()
								if itemdata then
									selected_item_data = itemdata
									selected_item_data.id = item_id
								end
							end
						)

						active_cards[cur_slot] = {
							action = function()
								buy_item(item_id)
							end
						}

						slot = slot + 1
					end
				end
			end
		end

		-- Bottom Action Buttons (placed directly below the card grid, rendered 100% by skin.button)
		local action_w = left_w
		local half_w = math.floor((action_w - 10) / 2)

		-- Row 1: Ammo Buttons (< Primary Ammo, > Secondary Ammo)
		local btn_pri_ammo = LF.Create("button", ui.buymenu)
			:SetPos(10, 390)
			:SetSize(half_w, 28)
			:SetText("< Primary Ammo")
		function btn_pri_ammo:OnClick()
			client.send("buy 61")
		end

		local btn_sec_ammo = LF.Create("button", ui.buymenu)
			:SetPos(10 + half_w + 10, 390)
			:SetSize(half_w, 28)
			:SetText("> Secondary Ammo")
		function btn_sec_ammo:OnClick()
			client.send("buy 62")
		end

		-- Row 2: [F1] Auto-Buy
		local btn_autobuy = LF.Create("button", ui.buymenu)
			:SetPos(10, 424)
			:SetSize(action_w, 28)
			:SetText("[F1] Auto-Buy")
		function btn_autobuy:OnClick()
			do_autobuy()
		end

		-- Row 3: [F2] Previous
		local btn_previous = LF.Create("button", ui.buymenu)
			:SetPos(10, 458)
			:SetSize(action_w, 28)
			:SetText("[F2] Previous")
		function btn_previous:OnClick()
			do_rebuy()
		end

		-- Row 4: 0 Close / 0 Back
		close_button = LF.Create("button", ui.buymenu)
			:SetPos(10, 492)
			:SetSize(action_w, 28)
			:SetText("0 Close")
		function close_button:OnClick()
			if current_category then
				list_shop()
			else
				ui.buymenu:Remove()
				ui.buymenu = nil
			end
		end

		-- Global Keyboard Shortcuts for Buy Menu
		function ui.buymenu:keypressed(key, isrepeat)
			if isrepeat then return end

			if key == "escape" or key == "b" then
				ui.buymenu:Remove()
				ui.buymenu = nil
				return
			end

			if key == "0" or key == "kp0" then
				if current_category then
					list_shop()
				else
					ui.buymenu:Remove()
					ui.buymenu = nil
				end
				return
			end

			if key == "f1" then
				do_autobuy()
				return
			end

			if key == "f2" then
				do_rebuy()
				return
			end

			if key == "," or key == "<" then
				client.send("buy 61")
				return
			end

			if key == "." or key == ">" then
				client.send("buy 62")
				return
			end

			-- Keys 1 to 9
			local num = tonumber(key) or tonumber(key:match("^kp(%d)$"))
			if num and num >= 1 and num <= 9 then
				if active_cards[num] and active_cards[num].action then
					active_cards[num].action()
				end
				return
			end
		end

		-- Initialize root shop view
		list_shop()
	end
end
