local LF = require "lib.loveframes"
local LG = love.graphics
local client = require "core.client"

return function(ui)
--weapon select window----------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

ui.weaponselect = LF.Create("container"):SetState("game")
ui.weaponselect:SetPos(love.graphics.getWidth() / 2 - ui.weaponselect:GetWidth(),
	(love.graphics.getHeight() - client.height) / 2)
ui.weaponselect:SetProperty("selindex", 0)
ui.weaponselect:SetProperty("itemheld", 0)
ui.weaponselect:SetProperty("slots", {})
ui.weaponselect:SetProperty("slot_active", 0)
ui.weaponselect:SetProperty("active", false)

ui.weaponselect.hud_slotheads = LF.CreateSpriteSheet("gfx/hud_slotheads.bmp", 10, 10)
ui.weaponselect.hud_slot = LF.CreateSprite("gfx/hud_slot.bmp")

function ui.weaponselect:queryItems(inventory)
	for i = 1, 9 do
		self.slots[i] = {}
	end
	-- 9 Slots
	for item_type, itemobject in pairs(inventory) do
		local itemdata = client.get_item_data(item_type)

		local slot = itemdata.slot or 1
		table.insert(self.slots[slot], item_type)
	end

	for i = 1, 9 do
		table.sort(self.slots[i])
	end
end

function ui.weaponselect:queryItemheld(itemheld)
	if itemheld == nil or itemheld == 0 then
		self.selindex = 0
		self.slot_active = 0
		self.active = false
		return
	end

	self.itemheld = itemheld

	local itemdata = client.get_item_data(itemheld)
	local slot = itemdata.slot or 1
	self.slot_active = slot

	for index, item_type in ipairs(self.slots[self.slot_active]) do
		if item_type == itemheld then
			self.selindex = index
		end
	end
end

function ui.weaponselect:Display(slot, x, y)
	x = x + self.x
	y = y + self.y

	local padding = 3
	local font = ui.font
	local hud_slot = self.hud_slot
	local width, height = hud_slot:getDimensions()
	local font_height = font:getHeight()
	local player = client.share.players[client.id]
	local text_offset_x = 50
	local text_offset_y = 2

	local item_offset = 20
	height = height + padding

	love.graphics.setBlendMode("add")
	for index in ipairs(slot) do
		if self.slots[self.slot_active] == slot and self.selindex == index then
			love.graphics.setColor(1, 1, 0, 0.6)
		else
			love.graphics.setColor(1, 0.6, 0, 0.3)
		end
		love.graphics.draw(hud_slot, x, y + (index - 1) * height)
	end
	love.graphics.setBlendMode("alpha")

	love.graphics.setFont(font)
	for index, item_type in ipairs(slot) do
		local itemdata = client.get_item_data(item_type)
		local name = itemdata.name
		local itemobject = player.i[item_type]
		local ammocap = itemobject.ac
		local ammoin = itemobject.am
		local label = name
		local ammo = ""
		if ammocap > 0 and ammoin > 0 then
			ammo = string.format("%s  |  %s", ammoin, ammocap)
		elseif ammocap == 0 and ammoin > 0 then
			label = string.format("%s (%s)", name, ammoin)
		end

		local length = font:getWidth(label)
		local scale = math.min(1, 90 / length)

		local x_pos = math.floor(x + text_offset_x)
		local y_pos = math.floor(y + text_offset_y + (index - 1) * height)

		-- Shadow
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.print(label, x_pos + 1, y_pos + 1, 0, scale, 1)
		love.graphics.print(ammo, x_pos + 1, y_pos + font_height + 1)
		-- Label
		love.graphics.setColor(1, 0.85, 0, 1)
		love.graphics.print(label, x_pos, y_pos, 0, scale, 1)
		love.graphics.print(ammo, x_pos, y_pos + font_height)
	end

	love.graphics.setColor(1, 1, 1, 1)
	for index, item_type in ipairs(slot) do
		-- Item
		local itemdata = client.get_item_data(item_type)
		local item_path = itemdata.common_path .. itemdata.dropped_image
		local item_gfx = client.map:getImage(item_path)
		local item_width, item_height = item_gfx:getDimensions()

		local x_pos = x + item_offset
		local y_pos = y + (index - 1) * height + height / 2
		local timer = love.timer.getTime() % 360
		--local timer = 0

		-- shadow
		love.graphics.setColor(0, 0, 0, 0.2)
		love.graphics.draw(item_gfx, x_pos + 3, y_pos + 3, timer, 1, 1, item_width / 2, item_height / 2)

		-- item
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(item_gfx, x_pos, y_pos, timer, 1, 1, item_width / 2, item_height / 2)
	end
end

function ui.weaponselect:selectSlot(slot)
	if not client.share.players then return end
	if not client.share.players[client.id] then return end
	local player = client.share.players[client.id]
	local c = 0
	for index in pairs(player.i) do
		c = c + 1
	end
	if c == 0 then return end -- There is nothing to do with empty inventory

	if slot < 0 or slot > 9 then
		return -- Out of bounds
	end

	local cursor_offset = 1
	if not self.active then
		self:activate()
		cursor_offset = 0
	end

	if #self.slots[slot] == 1 then
		-- Single item on slot
		self.slot_active = slot
		self.selindex = 1

		local item_type = self.slots[self.slot_active][self.selindex]
		client.send("weapon " .. item_type)

		-- Deactivate
		self.active = false
		-- Skip the list
		return
	end

	-- Check if its a valid slot and it has items
	if self.slots[slot] and #self.slots[slot] > 0 then
		-- If we're on a different slot than selected, then
		if self.slot_active ~= slot then
			self.selindex = 1
			self.slot_active = slot
		else
			if self.slots[self.slot_active][self.selindex + cursor_offset] then
				self.selindex = self.selindex + cursor_offset
			else
				self.selindex = 1
			end
		end
	end
end

function ui.weaponselect:selectNext()
	if not client.share.players then return end
	if not client.share.players[client.id] then return end
	local player = client.share.players[client.id]
	local c = 0
	for k, v in pairs(player.i) do
		c = c + 1
	end
	if c == 0 then return end -- There is nothing to do with empty inventory

	if self.selindex == 0 or self.slot_active == 0 then
		for i = 1, 9 do
			for order, item_type in ipairs(self.slots[i]) do
				if item_type then
					self.selindex = order
					self.slot_active = i
				end
			end
		end
	end -- self.selindex

	if self.slots[self.slot_active] then
		if self.slots[self.slot_active][self.selindex + 1] then
			self.selindex = self.selindex + 1
		else -- Check if the next slot has items
			for i = self.slot_active + 1, self.slot_active + 8 do
				local next_slot = (i - 1) % 9 + 1
				if #self.slots[next_slot] > 0 then
					self.selindex = 1
					self.slot_active = next_slot
					break
				end
			end
		end
	end
end

function ui.weaponselect:selectPrevious()
	if not client.share.players then return end
	if not client.share.players[client.id] then return end
	local player = client.share.players[client.id]

	local c = 0
	for k, v in pairs(player.i) do
		c = c + 1
	end
	if c == 0 then return end -- There is nothing to do with empty inventory


	if self.selindex == 0 or self.slot_active == 0 then
		for i = 1, 9 do
			for order, item_type in ipairs(self.slots[i]) do
				if item_type then
					self.selindex = order
					self.slot_active = i
				end
			end
		end
	end -- self.selindex

	if self.slots[self.slot_active] then
		if self.slots[self.slot_active][self.selindex - 1] then
			self.selindex = self.selindex - 1
		else -- Check if the next slot has items
			for i = self.slot_active + 8, self.slot_active + 1, -1 do
				local previous_slot = (i - 1) % 9 + 1
				if #self.slots[previous_slot] > 0 then
					self.selindex = #self.slots[previous_slot]
					self.slot_active = previous_slot
					break
				end
			end
		end
	end
end

function ui.weaponselect:Scroll(x, y)
	if LF.hoverobject and LF.hoverobject ~= self then
		return
	end
	if not self.active then
		self:activate()
	end

	if y < 0 then
		self:selectNext()
	elseif y > 0 then
		self:selectPrevious()
	end

	if self.selindex == 0 and self.slot_active == 0 then
		self.active = false
	end
end

function ui.weaponselect:OnControlKeyPressed(button, pressed)
	local slot = tonumber(button)
	if (not LF.inputobject) and (pressed and slot) then
		self:selectSlot(slot)
	end
end

function ui.weaponselect:OnMousePressed(x, y, button)
	if not self.active then
		return
	end

	if button == 1 then
		if self.slots[self.slot_active] and self.slots[self.slot_active][self.selindex] then
			local item_type = self.slots[self.slot_active][self.selindex]
			client.send("weapon " .. item_type)

			self.active = false
		else
			return
		end
	end
end

function ui.weaponselect:activate()
	if not LF.inputobject then
		self.active = true
	end
end

function ui.weaponselect:Draw()
	if not self.active then
		return
	end
	LF.collisioncount = LF.collisioncount + 1

	if not client.share.players then return end
	if not client.share.players[client.id] then return end

	local margin = 15
	local spacing = 0

	-- Draw list
	if self.slot_active > 0 then
		self:Display(self.slots[self.slot_active], (self.slot_active - 1) * margin, 12)
	end

	-- Draw squares
	LG.setBlendMode("add")
	LG.setColor(1, 0.6, 0, 0.3)
	for i = 0, #self.hud_slotheads do
		local slot = self.hud_slotheads[i]
		if (i + 1) == self.slot_active then
			LG.setColor(1, 1, 0, 0.6)
		elseif i == self.slot_active then
			spacing = self.hud_slot:getWidth()
			LG.setColor(1, 0.6, 0, 0.3)
		else
			LG.setColor(1, 0.6, 0, 0.3)
		end

		if #self.slots[i + 1] == 0 then
			LG.setColor(0.7, 0, 0, 0.3)
		end
		LG.draw(slot, self.x + i * margin + spacing, self.y)
	end
	LG.setBlendMode("alpha")
end

end
