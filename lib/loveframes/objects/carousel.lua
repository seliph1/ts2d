--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	local newobject = loveframes.NewObject("carousel", "loveframes_object_carousel", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
	--]] ---------------------------------------------------------
	function newobject:initialize()
		self.type = "carousel"
		self.width = 300
		self.height = 200
		self.collide = true

		self.item_width = self.width * 0.8
		self.padding = 10

		self.offsetx = 0
		self.target_offsetx = 0

		self.dragging = false
		self.start_mx = 0
		self.start_offsetx = 0

		self.items = {}

		self.internal = false
		self.internals = {}

		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: IsHoverInside()
	- desc: returns whether the hovered object is the carousel or its items
	--]] ---------------------------------------------------------
	function newobject:IsHoverInside()
		local obj = loveframes.GetHoverObject()
		while obj do
			if obj == self then
				return true
			end
			obj = obj.parent
		end
		return false
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
	--]] ---------------------------------------------------------
	function newobject:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		local parent = self.parent
		local base = loveframes.base
		local update = self.Update

		self:CheckHover()

		-- move to parent if there is a parent
		if parent ~= base then
			self.x = self.parent.x + self.staticx
			self.y = self.parent.y + self.staticy
		end

		local mx, my = love.mouse.getPosition()

		if self.dragging then
			local dx = mx - self.start_mx
			self.target_offsetx = self.start_offsetx + dx
			self.offsetx = self.target_offsetx

			if not love.mouse.isDown(1) then
				-- stop dragging (fallback in case mousereleased was missed)
				self:StopDragging(mx)
			end
		else
			-- Snap interpolation
			self.offsetx = self.offsetx + (self.target_offsetx - self.offsetx) * dt * 10
		end

		-- Layout children
		local center_offset = (self.width - self.item_width) / 2
		local current_offset_x = self.offsetx + center_offset

		for i, child in ipairs(self.items) do
			child.staticx = current_offset_x
			child.staticy = self.padding
			current_offset_x = current_offset_x + self.item_width + self.padding
			child:update(dt)
		end

		for k, v in ipairs(self.internals) do
			v:update(dt)
		end

		if update then
			update(self, dt)
		end
	end

	--[[---------------------------------------------------------
	- func: draw()
	- desc: draws the object
	--]] ---------------------------------------------------------
	function newobject:draw()
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		self:SetDrawOrder()

		local drawfunc = self.Draw or self.drawfunc
		if drawfunc then
			drawfunc(self)
		end

		-- draw the children, clipped to the carousel's bounds
		local ox, oy, ow, oh = love.graphics.getScissor()
		love.graphics.intersectScissor(self.x, self.y, self.width, self.height)

		for i, child in ipairs(self.items) do
			-- Only draw if visible inside the carousel
			if child.x + child.width > self.x and child.x < self.x + self.width then
				child:draw()
			end
		end

		love.graphics.setScissor(ox, oy, ow, oh)

		-- draw borders on top
		drawfunc = self.DrawOver or self.drawoverfunc
		if drawfunc then
			drawfunc(self)
		end
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]] ---------------------------------------------------------
	function newobject:mousepressed(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		-- If hoverobject is within our bounds (even on children)
		if self:IsHoverInside() then
			if button == 1 then
				self.dragging = true
				self.start_mx = x
				self.start_offsetx = self.offsetx
			end
		end

		-- Only pass mousepressed to children if they are physically inside the bounds!
		for i, child in ipairs(self.items) do
			if child.x + child.width > self.x and child.x < self.x + self.width then
				child:mousepressed(x, y, button)
			end
		end
	end

	--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]] ---------------------------------------------------------
	function newobject:mousereleased(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		local was_dragging = false
		if self.dragging and button == 1 then
			local dx = math.abs(x - self.start_mx)
			if dx > 5 then
				was_dragging = true
			end
			self:StopDragging(x)
		end

		if not was_dragging then
			for i, child in ipairs(self.items) do
				if child.x + child.width > self.x and child.x < self.x + self.width then
					child:mousereleased(x, y, button)
				end
			end
		end
	end

	--[[---------------------------------------------------------
	- func: StopDragging(mx)
	- desc: Ends the drag and calculates the snap target
--]] ---------------------------------------------------------
	function newobject:StopDragging(mx)
		self.dragging = false
		local dx = mx - self.start_mx

		local item_space = self.item_width + self.padding

		-- self.offsetx represents -(index-1) * item_space
		local exact_index = -self.offsetx / item_space + 1

		local snap_index = math.floor(exact_index + 0.5)

		-- Add inertia based on drag distance
		if dx > 30 then
			snap_index = math.floor(exact_index)
		elseif dx < -30 then
			snap_index = math.ceil(exact_index)
		end

		if snap_index < 1 then snap_index = 1 end
		if snap_index > #self.items then snap_index = #self.items end
		if #self.items == 0 then snap_index = 1 end

		self.target_offsetx = -(snap_index - 1) * item_space
	end

	--[[---------------------------------------------------------
	- func: AddItem(object)
	- desc: adds a new item to the carousel
--]] ---------------------------------------------------------
	function newobject:AddItem(object)
		object:Remove()
		object.parent = self
		object:SetState(self.state)
		object.staticx = 0
		object.staticy = 0

		object.visible = true
		table.insert(self.items, object)
		object:SetSize(self.item_width, self.height - self.padding * 2)

		return object
	end

	--[[---------------------------------------------------------
	- func: RemoveItem(id)
	- desc: removes an item from the carousel
--]] ---------------------------------------------------------
	function newobject:RemoveItem(id)
		local tab = self.items[id]
		if tab then
			tab:Remove()
			table.remove(self.items, id)
		end
		return self
	end

	--[[---------------------------------------------------------
	- func: SetItemWidth(width)
	- desc: sets the width of each item
--]] ---------------------------------------------------------
	function newobject:SetItemWidth(width)
		self.item_width = width
		for i, child in ipairs(self.items) do
			child:SetWidth(width)
		end
		return self
	end

	---------- module end ----------
end
