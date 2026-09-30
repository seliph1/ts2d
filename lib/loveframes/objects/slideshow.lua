--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- slideshow object
local SlideShow = loveframes.NewObject("slideshow", "loveframes_object_slideshow", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function SlideShow:initialize()
	self.type = "slideshow"
	self.width = 300
	self.height = 200
	self.tab = 1
	-- auto-advance
	self.interval = 8
	self.timer = 0
	self.autoplay = true
	-- navigation dots
	self.dotradius = 5
	self.dotspacing = 16
	self.dotbottom = 14
	self.dots = {}
	self.internal = false
	self.internals = {}
	self.children = {}
	self.OnTabChange = nil

	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: UpdateDots()
	- desc: computes the screen position of the navigation dots
			(grouped, horizontally centered, near the bottom)
--]]---------------------------------------------------------
function SlideShow:UpdateDots()
	local dots = self.dots
	local n = #self.children
	-- clear
	for i = #dots, 1, -1 do
		dots[i] = nil
	end
	if n == 0 then
		return
	end
	local groupwidth = (n - 1) * self.dotspacing
	local startx = self.x + self.width / 2 - groupwidth / 2
	local cy = self.y + self.height - self.dotbottom
	for i = 1, n do
		dots[i] = { x = startx + (i - 1) * self.dotspacing, y = cy }
	end
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the element
--]]---------------------------------------------------------
function SlideShow:update(dt)
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

	-- auto-advance to the next slide
	if self.autoplay and #self.children > 1 then
		self.timer = self.timer + dt
		if self.timer >= self.interval then
			self.timer = self.timer - self.interval
			local nexttab = self.tab + 1
			if nexttab > #self.children then
				nexttab = 1
			end
			self:SwitchToTab(nexttab)
		end
	end

	self:UpdateDots()

	-- update the active slide
	local active = self.children[self.tab]
	if active then
		active.staticx = 0
		active.staticy = 0
		active:update(dt)
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
--]]---------------------------------------------------------
function SlideShow:draw()
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	self:SetDrawOrder()

	local drawfunc = self.Draw or self.drawfunc
	if drawfunc then
		drawfunc(self)
	end

	-- draw the active slide, clipped to the slideshow's bounds
	local active = self.children[self.tab]
	if active then
		local ox, oy, ow, oh = love.graphics.getScissor()
		love.graphics.intersectScissor(self.x, self.y, self.width, self.height)
		active:draw()
		love.graphics.setScissor(ox, oy, ow, oh)
	end

	-- draw the navigation dots (and border) on top of the slide
	drawfunc = self.DrawOver or self.drawoverfunc
	if drawfunc then
		drawfunc(self)
	end
end

--[[---------------------------------------------------------
	- func: GetDotAt(x, y)
	- desc: returns the index of the dot under the given point,
			or nil
--]]---------------------------------------------------------
function SlideShow:GetDotAt(x, y)
	local r = self.dotradius + 3
	for i, dot in ipairs(self.dots) do
		local dx = x - dot.x
		local dy = y - dot.y
		if (dx * dx + dy * dy) <= (r * r) then
			return i
		end
	end
	return nil
end

--[[---------------------------------------------------------
	- func: IsHoverInside()
	- desc: returns whether the hovered object is the slideshow
			or one of its descendants (the slide covers the dots,
			so the slideshow itself is rarely the hover object)
--]]---------------------------------------------------------
function SlideShow:IsHoverInside()
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
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function SlideShow:mousepressed(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	-- the active slide covers the dots, so self.hover is usually false over
	-- them; use the hover subtree check instead (still respects being
	-- covered by another frame)
	if button == 1 and self:IsHoverInside() then
		local dot = self:GetDotAt(x, y)
		if dot then
			local baseparent = self:GetBaseParent()
			if baseparent and baseparent.type == "frame" then
				baseparent:MakeTop()
			end
			-- a dot was clicked: switch instantly, don't pass it to the slide
			self:SwitchToTab(dot)
			return
		end
	end

	local active = self.children[self.tab]
	if active then
		active:mousepressed(x, y, button)
	end
end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function SlideShow:mousereleased(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local active = self.children[self.tab]
	if active then
		active:mousereleased(x, y, button)
	end
end

--[[---------------------------------------------------------
	- func: AddTab(object)
	- desc: adds a new slide to the slideshow
--]]---------------------------------------------------------
function SlideShow:AddTab(object)
	object:Remove()
	object.parent = self
	object:SetState(self.state)
	object.staticx = 0
	object.staticy = 0

	local num = #self.children + 1
	object.visible = (num == 1)
	table.insert(self.children, object)
	object:SetSize(self.width, self.height)

	return object
end
SlideShow.AddSlide = SlideShow.AddTab

--[[---------------------------------------------------------
	- func: SwitchToTab(tabnumber)
	- desc: makes the specified slide the active one
--]]---------------------------------------------------------
function SlideShow:SwitchToTab(tabnumber)
	if tabnumber < 1 or tabnumber > #self.children then
		return self
	end
	for k, v in ipairs(self.children) do
		v.visible = false
	end
	self.tab = tabnumber
	local tab = self.children[tabnumber]
	if tab then
		tab.visible = true
		-- the slide was not updated while hidden, so position it right away
		tab:UpdateZero()
	end
	self.timer = 0
	local onchange = self.OnTabChange
	if onchange then
		onchange(self, tabnumber)
	end
	return self
end
SlideShow.SwitchToSlide = SlideShow.SwitchToTab

--[[---------------------------------------------------------
	- func: RemoveTab(id)
	- desc: removes a slide from the slideshow
--]]---------------------------------------------------------
function SlideShow:RemoveTab(id)
	local tab = self.children[id]
	if tab then
		tab:Remove()
	end
	if self.tab > #self.children then
		self.tab = #self.children
	end
	if self.tab < 1 and #self.children > 0 then
		self.tab = 1
	end
	local active = self.children[self.tab]
	if active then
		active.visible = true
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetTabNumber()
	- desc: gets the index of the active slide
--]]---------------------------------------------------------
function SlideShow:GetTabNumber()
	return self.tab
end

--[[---------------------------------------------------------
	- func: SetInterval(seconds)
	- desc: sets how long (in seconds) each slide is shown
			before auto-advancing
--]]---------------------------------------------------------
function SlideShow:SetInterval(seconds)
	self.interval = seconds
	return self
end

--[[---------------------------------------------------------
	- func: GetInterval()
	- desc: gets the auto-advance interval in seconds
--]]---------------------------------------------------------
function SlideShow:GetInterval()
	return self.interval
end

--[[---------------------------------------------------------
	- func: SetAutoPlay(bool)
	- desc: sets whether or not the slideshow advances by itself
--]]---------------------------------------------------------
function SlideShow:SetAutoPlay(bool)
	self.autoplay = bool
	self.timer = 0
	return self
end

--[[---------------------------------------------------------
	- func: GetAutoPlay()
	- desc: gets whether or not the slideshow advances by itself
--]]---------------------------------------------------------
function SlideShow:GetAutoPlay()
	return self.autoplay
end

--[[---------------------------------------------------------
	- func: SetDotRadius(radius)
	- desc: sets the radius of the navigation dots
--]]---------------------------------------------------------
function SlideShow:SetDotRadius(radius)
	self.dotradius = radius
	return self
end

--[[---------------------------------------------------------
	- func: SetDotSpacing(spacing)
	- desc: sets the spacing between the navigation dots
--]]---------------------------------------------------------
function SlideShow:SetDotSpacing(spacing)
	self.dotspacing = spacing
	return self
end

--[[---------------------------------------------------------
	- func: SetDotBottom(distance)
	- desc: sets the distance of the dots from the bottom edge
--]]---------------------------------------------------------
function SlideShow:SetDotBottom(distance)
	self.dotbottom = distance
	return self
end

---------- module end ----------
end
