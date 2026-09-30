--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- menu object
	local Menu = loveframes.NewObject("menu", "loveframes_object_menu", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function Menu:initialize(menu)
		self.type = "menu"
		self.width = 80
		self.height = 25
		self.largest_item_width = 0
		self.largest_item_height = 0
		self.sub_menu = false
		self.internal = false
		self.parentmenu = nil
		self.internals = {}
		self.visible = false
		self.margin = 60
		self.lastselected = nil
		self.parent = loveframes.base
		self.state = "*"
		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]] ---------------------------------------------------------
	function Menu:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		self:CheckHover()
		local parent = self.parent
		local base = loveframes.base
		local update = self.Update
		local selected = self.lastselected
		-- move to parent if there is a parent
		if parent ~= base then
			self.x = self.parent.x + self.staticx
			self.y = self.parent.y + self.staticy
		end

		for index, internal in ipairs(self.internals) do
			internal:update(dt)
		end

		if self.children then
			for index, child in ipairs(self.children) do
				child:update(dt)
			end
		end

		local hoverobject = loveframes.GetHoverObject()
		if hoverobject and hoverobject.type == "menuoption" then
			local option = hoverobject
			local time = option:GetHoverTime()

			if option.menu
				and option.parent == self
				and option.activated == false
				and option.enabled
				and time > 0.2
			then
				option.activated = true
				option.menu.visible = true
				option.menu:MoveToTop()

				if selected then
					selected.activated = false
					selected.menu:Close()
				end
				self.lastselected = option
			end
		end

		if update then
			update(self, dt)
		end
	end

	-- Override
	function Menu:RedoLayout()
		self.largest_item_width = 0
		self.largest_item_height = 0
		for index, internal in ipairs(self.internals) do
			local width = internal.contentwidth
			local height = internal.contentheight + internal.margin * 2

			if width > self.largest_item_width then
				self.largest_item_width = width
			end
			if height > self.largest_item_height then
				self.largest_item_height = height
			end
		end

		local height = 0
		for index, internal in ipairs(self.internals) do
			internal:SetWidth(self.largest_item_width + self.margin)
			internal:SetY(height)
			height = height + internal.height
		end

		self.width = self.largest_item_width + self.margin
		self.height = height

		return self
	end

	---@override
	function Menu:SetParent(parent)
		if parent == loveframes.base then
			-- Dont add frames inside objects
			self.parent = loveframes.base
			self:SetState(loveframes.base.state)
			table.insert(loveframes.base.children, self)
		else
			-- It's an object that can update children
			if parent.children then
				if self.parent then
					self:Remove()
				end
				self.parent = parent
				self:SetState(parent.state)
				table.insert(parent.children, self)
			else
				-- Search for another object in the upper node tree
				if parent.parent then
					self:SetParent(parent.parent)
				end
			end
		end

		return self
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]] ---------------------------------------------------------
	function Menu:mousepressed(x, y, button)
		if not self:OnState() then return end

		local hoverobject = loveframes.GetHoverObject() or loveframes.base
		local submenu = self.sub_menu

		if not submenu then
			if self.visible then
				if hoverobject.type ~= "menu" and hoverobject.type ~= "menuoption" then
					self:Close()
				end
			end
		end

		if self.children then
			for index, child in ipairs(self.children) do
				child:mousepressed(x, y, button)
			end
		end
	end

	--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]] ---------------------------------------------------------
	function Menu:mousereleased(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		local internals = self.internals
		for k, v in ipairs(internals) do
			v:mousereleased(x, y, button)
		end

		if self.children then
			for k, v in ipairs(self.children) do
				v:mousereleased(x, y, button)
			end
		end
	end

	function Menu:Clear()
		self.internals = {}
		self.children = {}
		self:RedoLayout()
		return self
	end

	--[[---------------------------------------------------------
	- func: ConstructFromTable(tbl)
	- desc: Construct a menu from a given table
--]] ---------------------------------------------------------
	function Menu:ConstructFromTable(tbl)
		self:Clear()
		if type(tbl) ~= "table" then return self end
		for _, item in ipairs(tbl) do
			if item.type == "divider" then
				self:AddDivider()
			else
				local submenu_data = item.submenu or item.sub_menu
				if submenu_data and type(submenu_data) == "table" then
					local submenu = loveframes.objects["menu"]:new()
					submenu:ConstructFromTable(submenu_data)
					self:AddSubMenu(item.text, item.icon, submenu)
				else
					self:AddOption(item.text, item.icon, item.func)
				end
				if item.enabled ~= nil then
					self.internals[#self.internals]:SetEnabled(item.enabled)
				end
			end
		end
		return self
	end

	--[[---------------------------------------------------------
	- func: AddOption(text, icon, func)
	- desc: adds an option to the object
--]] ---------------------------------------------------------
	function Menu:AddOption(text, icon, func)
		local menuoption = loveframes.objects["menuoption"]:new(self)
		menuoption:SetText(text)
		menuoption:SetIcon(icon)
		menuoption:SetFunction(func)

		table.insert(self.internals, menuoption)

		self:RedoLayout()
		return self
	end

	function Menu:GetOption(n)
		return self.internals[n]
	end

	--[[---------------------------------------------------------
	- func: RemoveOption(id)
	- desc: removes an option
--]] ---------------------------------------------------------
	function Menu:RemoveOption(id)
		for k, v in ipairs(self.internals) do
			if k == id then
				table.remove(self.internals, k)
				return
			end
		end
		return self
	end

	--[[---------------------------------------------------------
	- func: AddSubMenu(text, icon, menu)
	- desc: adds a submenu to the object
--]] ---------------------------------------------------------
	function Menu:AddSubMenu(text, icon, menu)
		local menuoption = loveframes.objects["menuoption"]:new(self, "submenu_activator", menu)
		menuoption:SetText(text)
		menuoption:SetIcon(icon)
		if menu then
			menu.visible = false
			menu.sub_menu = true
			menu.parentmenu = self
			menu:SetParent(self)
		end
		table.insert(self.internals, menuoption)
		self:RedoLayout()
		return self
	end

	--[[---------------------------------------------------------
	- func: AddDivider()
	- desc: adds a divider to the object
--]] ---------------------------------------------------------
	function Menu:AddDivider()
		local menuoption = loveframes.objects["menuoption"]:new(self, "divider")
		table.insert(self.internals, menuoption)

		self:RedoLayout()
		return self
	end

	--[[---------------------------------------------------------
	- func: GetBaseMenu(t)
	- desc: gets the object's base menu
--]] ---------------------------------------------------------
	function Menu:GetBaseMenu()
		if self.sub_menu then
			return self.parentmenu:GetBaseMenu()
		else
			return self
		end
	end

	function Menu:Open(x, y)
		x = x or 0
		y = y or 0

		local sw, sh = love.graphics.getDimensions()

		-- Colapsar para cima se passar da tela
		if y + self.height > sh then
			if self.sub_menu then
				y = sh - self.height
			else
				y = y - self.height
			end
		end

		-- Colapsar para a esquerda se passar da tela
		if x + self.width > sw then
			if self.sub_menu and self.parentmenu then
				x = x - self.width - self.parentmenu.width
			else
				x = x - self.width
			end
		end

		-- Clamps de seguranca para evitar sumir no canto superior esquerdo
		if x < 0 then x = 0 end
		if y < 0 then y = 0 end

		self.visible = true
		self:SetAbsolutePos(x, y)
		self:MoveToTop()

		if self.sub_menu then
			self.visible = false
		end

		for index, internal in ipairs(self.internals) do
			if internal.type == "menuoption" then
				internal.visible = true
				if internal.menu then
					internal.menu:Open(x + self.width, y + internal.staticy)
					internal.activated = false
				end
			end
		end
	end

	function Menu:Close()
		self.visible = false
		self.activated = false

		self.lastselected = nil

		for index, internal in ipairs(self.internals) do
			if internal.type == "menuoption" then
				if internal.menu then
					internal.menu:Close()
					internal.activated = false
				end
			end
		end
		return self
	end

	---@override
	function Menu:SetVisible(visible)
		if visible == false then
			self:Close()
		end
	end

	---------- module end ----------
end
