--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- multichoicelist class
	local newobject = loveframes.NewObject("multichoicelist", "loveframes_object_multichoicelist", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function newobject:initialize(parent)
		self.type = "multichoicelist"
		self.parent = parent
		self.state = parent.state
		self.staticx = 0
		self.staticy = parent.height + 1
		self.width = parent.width
		self.height = 0
		self.clickx = 0
		self.clicky = 0
		self.padding = parent.listpadding
		self.spacing = parent.listspacing
		self.buttonscrollamount = parent.buttonscrollamount
		self.mousewheelscrollamount = parent.mousewheelscrollamount
		self.offsety = 0
		self.offsetx = 0
		self.extrawidth = 0
		self.extraheight = 0
		self.canremove = false
		self.dtscrolling = parent.dtscrolling
		self.internal = true
		self.vbar = false
		self.children = {}
		self.internals = {}

		for k, v in ipairs(parent.choices) do
			local row = loveframes.objects["multichoicerow"]:new()
			row:SetText(v)
			self:AddItem(row)
		end
		-- apply template properties to the object
		loveframes.ApplyTemplatesToObject(self)
		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]] ---------------------------------------------------------
	function newobject:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		local width = love.graphics.getWidth()
		local height = love.graphics.getHeight()
		local parent = self.parent
		local base = loveframes.base
		local update = self.Update
		local internals = self.internals
		local children = self.children

		-- move to parent if there is a parent
		if parent ~= base then
			self.x = parent.x + self.staticx
			self.y = parent.y + self.staticy
		end

		if self.x < 0 then
			self.x = 0
		end

		if self.x + self.width > width then
			self.x = width - self.width
		end

		if self.y < 0 then
			self.y = 0
		end

		if self.y + self.height > height then
			self.y = height - self.height
		end

		for k, v in ipairs(internals) do
			v:update(dt)
		end

		for k, v in ipairs(children) do
			v:update(dt)
			v:SetClickBounds(self.x, self.y, self.width, self.height)
			v.y = (v.parent.y + v.staticy) - self.offsety
			v.x = (v.parent.x + v.staticx) - self.offsetx
		end

		if update then
			update(self, dt)
		end
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]] ---------------------------------------------------------
	function newobject:mousepressed(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		local selfcol = loveframes.BoundingBox(x, self.x, y, self.y, 1, self.width, 1, self.height)
		local internals = self.internals
		local children = self.children

		if not selfcol and self.canremove and button == 1 then
			self:Remove()
		end
		for k, v in ipairs(internals) do
			v:mousepressed(x, y, button)
		end
		for k, v in ipairs(children) do
			v:mousepressed(x, y, button)
		end
	end

	--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]] ---------------------------------------------------------
	function newobject:mousereleased(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		local internals = self.internals
		local children = self.children

		self.canremove = true

		for k, v in ipairs(internals) do
			v:mousereleased(x, y, button)
		end

		for k, v in ipairs(children) do
			v:mousereleased(x, y, button)
		end
	end

	--[[---------------------------------------------------------
	- func: wheelmoved(x, y)
	- desc: called when the player moves a mouse wheel
--]] ---------------------------------------------------------
	function newobject:wheelmoved(x, y)
		local toplist = self:IsTopList()
		local internals = self.internals
		local scrollamount = self.mousewheelscrollamount

		if self.vbar and toplist then
			local bar = internals[1].internals[1].internals[1]
			local dtscrolling = self.dtscrolling
			if dtscrolling then
				local dt = love.timer.getDelta()
				bar:Scroll(-y * scrollamount * dt)
			else
				bar:Scroll(-y * scrollamount)
			end
		end
	end

	--[[---------------------------------------------------------
	- func: AddItem(object)
	- desc: adds an item to the object
--]] ---------------------------------------------------------
	function newobject:AddItem(object)
		if object.type ~= "multichoicerow" then
			return
		end

		object.parent = self
		object.state = self.state
		table.insert(self.children, object)

		self:CalculateSize()
		self:RedoLayout()
	end

	--[[---------------------------------------------------------
	- func: RemoveItem(object)
	- desc: removes an item from the object
--]] ---------------------------------------------------------
	function newobject:RemoveItem(object)
		local children = self.children

		for k, v in ipairs(children) do
			if v == object then
				table.remove(children, k)
			end
		end

		self:CalculateSize()
		self:RedoLayout()
	end

	--[[---------------------------------------------------------
	- func: CalculateSize()
	- desc: calculates the size of the object's children
--]] ---------------------------------------------------------
	function newobject:CalculateSize()
		self.height = self.padding

		if self.parent.listheight then
			self.height = self.parent.listheight
		else
			for k, v in ipairs(self.children) do
				self.height = self.height + (v.height + self.spacing)
			end
		end

		if self.height > love.graphics.getHeight() then
			self.height = love.graphics.getHeight()
		end

		local numitems = #self.children
		local height = self.height
		local padding = self.padding
		local spacing = self.spacing
		local itemheight = self.padding
		local vbar = self.vbar
		local children = self.children

		for k, v in ipairs(children) do
			itemheight = itemheight + v.height + spacing
		end

		self.itemheight = (itemheight - spacing) + padding

		if self.itemheight > height then
			self.extraheight = self.itemheight - height
			if not vbar then
				local scroll = loveframes.objects["scrollbody"]:new(self, "vertical")
				table.insert(self.internals, scroll)
				self.vbar = true
			end
		else
			if vbar then
				self.internals[1]:Remove()
				self.vbar = false
				self.offsety = 0
			end
		end
	end

	--[[---------------------------------------------------------
	- func: RedoLayout()
	- desc: used to redo the layour of the object
--]] ---------------------------------------------------------
	function newobject:RedoLayout()
		local children = self.children
		local padding = self.padding
		local spacing = self.spacing
		local starty = padding
		local vbar = self.vbar

		if #children > 0 then
			for k, v in ipairs(children) do
				v.staticx = padding
				v.staticy = starty
				if vbar then
					v.width = (self.width - self.internals[1].width) - padding * 2
					self.internals[1].staticx = self.width - self.internals[1].width
					self.internals[1].height = self.height
				else
					v.width = self.width - padding * 2
				end
				starty = starty + v.height
				starty = starty + spacing
			end
		end
	end

	--[[---------------------------------------------------------
	- func: SetPadding(amount)
	- desc: sets the object's padding
--]] ---------------------------------------------------------
	function newobject:SetPadding(amount)
		self.padding = amount
	end

	--[[---------------------------------------------------------
	- func: SetSpacing(amount)
	- desc: sets the object's spacing
--]] ---------------------------------------------------------
	function newobject:SetSpacing(amount)
		self.spacing = amount
	end

	--[[---------------------------------------------------------
	- func: Close()
	- desc: closes the object
--]] ---------------------------------------------------------
	function newobject:Close()
		self:Remove()
	end

	---------- module end ----------
end
