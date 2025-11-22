--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- scrollbar class
local newobject = loveframes.NewObject("scrollbar", "loveframes_object_scrollbar", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize(parent, bartype)
	self.type = "scrollbar"
	self.bartype = bartype
	self.parent = parent
	self.x = 0
	self.y = 0
	self.staticx = 0
	self.staticy = 0
	self.maxx = 0
	self.maxy = 0
	self.clickx = 0
	self.clicky = 0
	self.starty = 0
	self.lastwidth = 0
	self.lastheight = 0
	self.lastx = 0
	self.lasty = 0
	self.internal = true
	self.hover = false
	self.autoscroll = false
	self.dragging = false
	self.internal = true
	if self.bartype == "vertical" then
		self.width = self.parent.width
		self.height = 5
	elseif self.bartype == "horizontal" then
		self.width = 5
		self.height = self.parent.height
	end
	-- apply template properties to the object
	loveframes.ApplyTemplatesToObject(self)
	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function newobject:update(dt)
	local visible = self.visible
	local alwaysupdate = self.alwaysupdate
	if not visible then
		if not alwaysupdate then
			return
		end
	end
	self:CheckHover()
	local x, y     = love.mouse.getPosition()
	local bartype  = self.bartype
	local parent = self.parent
	local scrollable = parent.parent.parent

	if bartype == "vertical" then
		self.width 	= parent.width
	elseif bartype == "horizontal" then
		self.height = parent.height
	end
	self.dragging = self:IsDragging()

	if bartype == "vertical" then
		self.height = self:CalculateBarSize()
		self.maxy = parent.y + (parent.height - self.height)
		self.x = parent.x + parent.width - self.width
		self.y = parent.y + self.staticy
		-- If dragging.
		if self:IsDragging() and scrollable.itemheight > scrollable.height then
			self:DragY()
			if self.staticy ~= self.lasty then
				if scrollable.OnScroll then
					scrollable.OnScroll(scrollable)
				end
				self.lasty = self.staticy
			end
		end
		local space = (self.maxy - parent.y)
		local remaining = (0 + self.staticy)
		local percent = 0
		if space > 0 then
			percent = remaining/space
		end
		local extra = scrollable.extraheight * percent
		scrollable.offsety = 0 + extra
		if self.staticy > space then
			self.staticy = space
			scrollable.offsety = scrollable.extraheight
		end
		if self.staticy < 0 then
			self.staticy = 0
			scrollable.offsety = 0
		end

	elseif bartype == "horizontal" then
		self.width = self:CalculateBarSize()
		self.maxx = parent.x + (parent.width) - self.width
		self.x = parent.x + self.staticx
		self.y = parent.y + self.staticy
		if self:IsDragging() and scrollable.itemwidth > scrollable.width then
			self:DragX()
			if self.staticx ~= self.lastx then
				if scrollable.OnScroll then
					scrollable.OnScroll(scrollable)
				end
				self.lastx = self.staticx
			end
		end
		local space      = (self.maxx - parent.x)
		local remaining  = (0 + self.staticx)
		local percent = 0
		if space > 0 then
			percent = remaining/space
		end
		local extra      = scrollable.extrawidth * percent
		scrollable.offsetx = 0 + extra
		if self.staticx > space then
			self.staticx = space
			scrollable.offsetx = scrollable.extrawidth
		end
		if self.staticx < 0 then
			self.staticx = 0
			scrollable.offsetx = 0
		end
	end
	local update = self.Update
	if update then update(self, dt) end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button)
	local visible = self.visible
	local hover = self.hover
	if not visible then
		return
	end
	if not hover then
		return
	end
	local baseparent = self:GetBaseParent()
	if baseparent.type == "frame" then
		baseparent:MakeTop()
	end

end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function newobject:mousereleased(x, y, button)
	if not self.visible then return end
end
--[[---------------------------------------------------------
	- func: SetMaxX(x)
	- desc: sets the object's max x position
--]]---------------------------------------------------------
function newobject:SetMaxX(x)
	self.maxx = x
end

--[[---------------------------------------------------------
	- func: SetMaxY(y)
	- desc: sets the object's max y position
--]]---------------------------------------------------------
function newobject:SetMaxY(y)
	self.maxy = y
end

--[[---------------------------------------------------------
	- func: Scroll(amount)
	- desc: scrolls the object
--]]---------------------------------------------------------
function newobject:Scroll(amount)
	local bartype = self.bartype
	local scrollable = self.parent.parent.parent
	local onscroll = scrollable.OnScroll

	if bartype == "vertical" then
		local newy = (self.y + amount)
		if newy > self.maxy then
			self.staticy = self.maxy - self.parent.y
		elseif newy < self.parent.y then
			self.staticy = 0
		else
			self.staticy = self.staticy + amount
		end
	elseif bartype == "horizontal" then
		local newx = (self.x + amount)
		if newx > self.maxx then
			self.staticx = self.maxx - self.parent.x
		elseif newx < self.parent.x then
			self.staticx = 0
		else
			self.staticx = self.staticx + amount
		end
	end
	if onscroll then
		onscroll(scrollable)
	end
end

--[[---------------------------------------------------------
	- func: ScrollTo(position)
	- desc: scrolls the object
--]]---------------------------------------------------------
function newobject:ScrollTo(position)
	local bartype = self.bartype
	local scrollable = self.parent.parent.parent
	local onscroll = scrollable.OnScroll
	if bartype == "vertical" then
		local maxRealPos = self.parent.height - self:CalculateBarSize()
		if position > 1 then
			self.staticy = maxRealPos
		elseif position < 0 then
			self.staticy = 0
		else
			self.staticy = position * maxRealPos
		end
	elseif bartype == "horizontal" then
		local maxRealPos = self.parent.width - self:CalculateBarSize()
		if position > 1 then
			self.staticx = maxRealPos
		elseif position < 0 then
			self.staticx = 0
		else
			self.staticx = position * maxRealPos
		end
	end
	if onscroll then
		onscroll(scrollable)
	end
end

--[[---------------------------------------------------------
	- func: ScrollTop(position)
	- desc: scrolls the object to the top
--]]---------------------------------------------------------
function newobject:ScrollTop()
	local bartype = self.bartype
	local scrollable = self.parent.parent.parent
	local onscroll = scrollable.OnScroll
	if bartype == "vertical" then
		self.staticy = 0
	elseif bartype == "horizontal" then
		self.staticx = 0
	end
	if onscroll then
		onscroll(scrollable)
	end
end
--[[---------------------------------------------------------
	- func: ScrollBottom(position)
	- desc: scrolls the object to the bottom
--]]---------------------------------------------------------
function newobject:ScrollBottom()
	local bartype = self.bartype
	local scrollable = self.parent.parent.parent
	local parent = self.parent
	local onscroll = scrollable.OnScroll
	if bartype == "vertical" then
		self.staticy = parent.height - self:CalculateBarSize()
	elseif bartype == "horizontal" then
		self.staticx = parent.width - self:CalculateBarSize()
	end
	if onscroll then
		onscroll(scrollable)
	end
end

--[[---------------------------------------------------------
	- func: GetBarType()
	- desc: gets the object's bartype
--]]---------------------------------------------------------
function newobject:GetBarType()
	return self.bartype
end

--[[---------------------------------------------------------
	- func: CalculateBarSize()
	- desc: calculates the object's bar size
--]]---------------------------------------------------------
function newobject:CalculateBarSize()
	local bartype = self.bartype
	local parent = self.parent
	local scrollable = parent.parent.parent
	local size
	if bartype == "vertical" then
		size = parent.height * (scrollable.height / math.max(scrollable.itemheight, scrollable.height) )
	elseif bartype == "horizontal" then
		size = parent.width * (scrollable.width / math.max(scrollable.itemwidth, scrollable.width) )
	end
	size = math.floor( size )
	if size < 20 then
		size = 20
	end
	return size
end


--[[---------------------------------------------------------
	- func: GetBarAmount()
	- desc: gets the object's bar amount scrolled
--]]---------------------------------------------------------
function newobject:GetBarAmount()
	local bartype = self.bartype
	if bartype == "vertical" then
		local maxRealPos = self.parent.height - self.height
		return self.staticy/maxRealPos
	elseif bartype == "horizontal" then
		local maxRealPos = self.parent.width - self.width
		return self.staticx/maxRealPos
	end
end

---------- module end ----------
end
