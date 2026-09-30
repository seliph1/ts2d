--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------
	local newobject = loveframes.NewObject("dockzone", "loveframes_object_dockzone", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function newobject:initialize()
		self.type = "dockzone"
		self.width = 100
		self.height = 100

		self.highlight = false
		self.last_dragging = nil
		self.docked_child = nil

		self:SetDrawFunc()
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

		local dragging = loveframes.GetDraggingObject()
		if self.highlight then
			if not dragging and not self.docked_child then
				self:Dock(self.last_dragging)
				self.last_dragging = nil
			end
		end

		if dragging then
			local mx, my = love.mouse.getPosition()
			if dragging == self.docked_child then
				self:Undock()
			end

			-- check intersection
			if mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height then
				self.highlight = true
				self.last_dragging = dragging
			else
				self.highlight = false
				self.last_dragging = nil
			end
		else
			self.highlight = false
			self.last_dragging = nil
		end

		if self.docked_child then
			self.docked_child:update(dt)
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

		if self.docked_child then
			self.docked_child:draw()
		end

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

		if self.docked_child then
			self.docked_child:mousepressed(x, y, button)
		end
	end

	--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]] ---------------------------------------------------------
	function newobject:mousereleased(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		if self.docked_child then
			self.docked_child:mousereleased(x, y, button)
		end
	end

	--[[---------------------------------------------------------
	- func: DockFrame(object)
	- desc: docks a object into this zone
--]] ---------------------------------------------------------
	function newobject:Dock(object)
		if self.docked_child then
			-- Don't dock if we're taking care of a child already.
			return
		end

		object:Remove()
		object.parent = self
		object.staticx = 0
		object.staticy = 0

		self.docked_child = object

		-- Store original size if we want to restore later, but resizing it to fit the dockzone makes sense
		if object:GetResizable() then
			object:SetSize(self.width, self.height)
		end

		object.docked = true
		if object.OnDock then
			object:OnDock(self)
		end
	end

	--[[---------------------------------------------------------
	- func: Undock()
	- desc: undocks an object from this zone (tear off)
--]] ---------------------------------------------------------
	function newobject:Undock()
		local object = self.docked_child
		self.docked_child = nil


		object:SetParent(loveframes.base)
		object.docked = nil
	end

	---------- module end ----------
end
