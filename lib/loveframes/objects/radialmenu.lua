--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	local newobject = loveframes.NewObject("radialmenu", "loveframes_object_radialmenu", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function newobject:initialize()
		self.type = "radialmenu"
		self.options = {}
		self.hovered_option = nil
		self.visible = false
		self.collide = true
		self.context = loveframes.base
		self.radius_inner = 25
		self.radius_outer = 110
		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: AddOption(text, icon, func)
	- desc: adds a slice to the radial menu
--]] ---------------------------------------------------------
	function newobject:AddOption(text, icon, func)
		table.insert(self.options, {
			text = text,
			icon = icon,
			func = func
		})
		return self
	end

	--[[---------------------------------------------------------
	- func: Open(x, y)
	- desc: opens the radial menu at coordinates
--]] ---------------------------------------------------------
	function newobject:Open(x, y)
		local mx, my = love.mouse.getPosition()
		local cx = x or mx
		local cy = y or my

		-- The object bounds are a square encompassing the outer radius
		self.width = self.radius_outer * 2
		self.height = self.radius_outer * 2
		self.x = cx - self.radius_outer
		self.y = cy - self.radius_outer

		self.visible = true
		self:MoveToTop()
		self.hovered_option = nil
		self.block_click = true
		return self
	end

	--[[---------------------------------------------------------
	- func: Close()
	- desc: hides the menu
--]] ---------------------------------------------------------
	function newobject:Close()
		self.visible = false
		self.hovered_option = nil
		return self
	end

	function newobject:update(dt)
		if not self.visible then return end
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		local mx, my = love.mouse.getPosition()
		local cx = self.x + self.radius_outer
		local cy = self.y + self.radius_outer

		-- Calculate distance from center
		local dx = mx - cx
		local dy = my - cy
		local dist = math.sqrt(dx * dx + dy * dy)

		if dist > self.radius_inner and dist <= self.radius_outer and #self.options > 0 then
			-- Calculate angle from -pi to pi
			local angle = math.atan2(dy, dx)
			if angle < 0 then angle = angle + math.pi * 2 end

			-- Size of each slice in radians
			local slice = (math.pi * 2) / #self.options

			-- Offset angle by half a slice so the first slice is centered directly on angle 0 (right)
			local offset_angle = (angle + slice / 2) % (math.pi * 2)

			self.hovered_option = math.floor(offset_angle / slice) + 1
		else
			self.hovered_option = nil
		end

		self:CheckHover()

		-- Check if we should close when clicking outside
		local hoverobject = loveframes.GetHoverObject()
		if love.mouse.isDown(1, 2, 3) and hoverobject ~= self then
			self:Close()
		end
	end

	--[[---------------------------------------------------------
	- func: CheckHover()
	- desc: custom hover check for the radial shape
--]] ---------------------------------------------------------
	function newobject:CheckHover()
		local selfcol        = (self.hovered_option ~= nil)

		local collisioncount = loveframes.collisioncount
		local hoverobject    = loveframes.GetHoverObject()

		-- check if the mouse is colliding with the object (only on the slices)
		if self:OnState() and self:IsVisible() then
			local collide = self.collide
			if selfcol and collide then
				loveframes.collisioncount = collisioncount + 1
				loveframes.collisions = self
			end
		end

		-- check if the object is being hovered
		if hoverobject == self then
			self.hover = true
		else
			self.hover = false
		end

		local hover = self.hover
		local calledmousefunc = self.calledmousefunc
		-- check for mouse enter and exit events
		if hover then
			if not calledmousefunc then
				self.hovertime = love.timer.getTime()
				if self.OnMouseEnter then self:OnMouseEnter() end
				self.calledmousefunc = true
			end
		else
			if calledmousefunc then
				self.hovertime = 0
				if self.OnMouseExit then self:OnMouseExit() end
				self.calledmousefunc = false
			end
		end
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]] ---------------------------------------------------------
	function newobject:mousepressed(x, y, button)
		if not self.visible then return end
		if not self:OnState() then return end

		-- Close on right click
		if button == 2 then
			self:Close()
		end
	end

	--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]] ---------------------------------------------------------
	function newobject:mousereleased(x, y, button)
		if not self.visible then return end
		if not self:OnState() then return end

		-- Prevents the menu from instantly closing on the same frame it was opened
		if self.block_click then
			self.block_click = false
			return
		end

		if button == 1 then
			if self.hovered_option then
				local opt = self.options[self.hovered_option]
				if opt.func then
					opt.func()
				end
			end
			-- Any left click inside the bounds (even empty center) closes the menu
			self:Close()
		end
	end

	---------- module end ----------
end
