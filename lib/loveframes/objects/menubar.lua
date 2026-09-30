--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- menubar class
	local Menubar = loveframes.NewObject("menubar", "loveframes_object_menubar", true)

	--[[---------------------------------------------------------
		- func: initialize()
		- desc: initializes the object
	--]] ---------------------------------------------------------
	function Menubar:initialize()
		self.type = "menubar"
		self.width = love.graphics.getWidth()
		self.height = 25
		self.internal = false

		self.items = {}
		self.hovered_index = nil
		self.menu_active = false
		self.active_menu = nil

		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
		- func: update(deltatime)
		- desc: updates the element
	--]] ---------------------------------------------------------
	function Menubar:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		local parent = self.parent
		local base = loveframes.base
		local update = self.Update

		-- Align to parent width if parent isn't base
		if parent ~= base then
			self.x = self.parent.x + self.staticx
			self.y = self.parent.y + self.staticy
		else
			self.width = love.graphics.getWidth()
		end

		self:CheckHover()

		-- Recalculate item sizes/positions
		local skin = loveframes.GetActiveSkin()
		local font = (skin and skin.controls and skin.controls.menubar_text_font) or loveframes.basicfont
		local current_x = 10
		local padding = 15

		for i, item in ipairs(self.items) do
			item.width = font:getWidth(item.text) + padding * 2
			item.x = current_x
			current_x = current_x + item.width
		end

		-- Hover check for menu bar items
		local mx, my = love.mouse.getPosition()
		self.hovered_index = nil

		if self.hover then
			for i, item in ipairs(self.items) do
				local ix = self.x + item.x
				local iy = self.y
				if mx >= ix and mx <= ix + item.width and my >= iy and my <= iy + self.height then
					self.hovered_index = i
					break
				end
			end
		end

		-- Switch active menu if hovering over another item
		if self.menu_active and self.hovered_index then
			local item = self.items[self.hovered_index]
			if item.menu and item.menu ~= self.active_menu then
				if self.active_menu then
					self.active_menu:Close()
				end
				self.active_menu = item.menu
				item.menu:Open(self.x + item.x, self.y + self.height)
			end
		end

		-- Check if active menu has been closed externally
		if self.menu_active and self.active_menu and not self.active_menu.visible then
			self.menu_active = false
			self.active_menu = nil
		end

		if update then
			update(self, dt)
		end
	end

	--[[---------------------------------------------------------
		- func: mousepressed(x, y, button)
		- desc: mouse button pressed
	--]] ---------------------------------------------------------
	function Menubar:mousepressed(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		if self.hovered_index and button == 1 then
			local item = self.items[self.hovered_index]
			if item.menu then
				if self.menu_active and self.active_menu == item.menu then
					-- Toggle close
					item.menu:Close()
					self.menu_active = false
					self.active_menu = nil
				else
					if self.active_menu then
						self.active_menu:Close()
					end
					self.active_menu = item.menu
					self.menu_active = true
					item.menu:Open(self.x + item.x, self.y + self.height)
				end
			end
		end
	end

	--[[---------------------------------------------------------
		- func: AddMenu(text, menu)
		- desc: adds a menu to the menubar
	--]] ---------------------------------------------------------
	function Menubar:AddMenu(text, menu)
		if not menu then
			menu = loveframes.Create("menubarmenu")
		end
		table.insert(self.items, { text = text, menu = menu })
		menu:SetParent(loveframes.base)
		menu.visible = false
		return menu
	end

	--[[---------------------------------------------------------
		- func: Remove()
		- desc: removes the object and associated menus
	--]] ---------------------------------------------------------
	function Menubar:Remove()
		for _, item in ipairs(self.items) do
			if item.menu then
				item.menu:Remove()
			end
		end

		local pinternals = self.parent.internals
		local pchildren = self.parent.children
		if pinternals then
			for k, v in pairs(pinternals) do
				if v == self then
					table.remove(pinternals, k)
				end
			end
		end
		if pchildren then
			for k, v in pairs(pchildren) do
				if v == self then
					table.remove(pchildren, k)
				end
			end
		end
		return self
	end

	---------- module end ----------
end
