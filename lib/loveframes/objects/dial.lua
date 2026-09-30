--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- dial object
local newobject = loveframes.NewObject("dial", "loveframes_object_dial", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()

	self.type = "dial"
	self.width = 50
	self.height = 50
	-- angle in degrees, 0 = up (12 o'clock), increasing clockwise
	self.angle = 0
	self.min = 0
	self.max = 360
	self.snap = 0
	self.enabled = true
	self.dragging = false
	self.internal = false
	self.internals = {}
	self.OnValueChanged = nil
	self.OnRelease = nil

	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function newobject:update(dt)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	self:CheckHover()
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update

	-- move to parent if there is a parent
	if parent ~= base then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end

	-- while dragging, keep following the mouse even if it leaves the dial
	if self.dragging and self.enabled then
		local mx, my = love.mouse.getPosition()
		self:SetAngleFromPos(mx, my)
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
function newobject:draw()
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	self:SetDrawOrder()
	local drawfunc = self.Draw or self.drawfunc
	if drawfunc then
		drawfunc(self)
	end
	drawfunc = self.DrawOver or self.drawoverfunc
	if drawfunc then
		drawfunc(self)
	end
end

--[[---------------------------------------------------------
	- func: IsInsideCircle(x, y)
	- desc: returns whether the given point is within the dial
--]]---------------------------------------------------------
function newobject:IsInsideCircle(x, y)
	local radius = math.min(self.width, self.height) / 2
	local dx = x - (self.x + self.width / 2)
	local dy = y - (self.y + self.height / 2)
	return (dx * dx + dy * dy) <= (radius * radius)
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	if not self.enabled then return end

	if self.hover and button == 1 and self:IsInsideCircle(x, y) then
		local baseparent = self:GetBaseParent()
		if baseparent and baseparent.type == "frame" then
			baseparent:MakeTop()
		end
		self.dragging = true
		loveframes.downobject = self
		self:SetAngleFromPos(x, y)
	end

	for k, v in ipairs(self.internals) do
		v:mousepressed(x, y, button)
	end
end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function newobject:mousereleased(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	if self.dragging then
		self.dragging = false
		if loveframes.downobject == self then
			loveframes.downobject = false
		end
		local onrelease = self.OnRelease
		if onrelease then
			onrelease(self, self.angle)
		end
	end

	for k, v in ipairs(self.internals) do
		v:mousereleased(x, y, button)
	end
end

--[[---------------------------------------------------------
	- func: SetAngleFromPos(mx, my)
	- desc: sets the angle from a point (e.g. the mouse), based
			on its direction from the dial's center
--]]---------------------------------------------------------
function newobject:SetAngleFromPos(mx, my)
	local cx = self.x + self.width / 2
	local cy = self.y + self.height / 2
	-- 0 = up, clockwise positive
	local angle = math.deg(math.atan2(mx - cx, -(my - cy)))
	if angle < 0 then
		angle = angle + 360
	end
	self:SetAngle(angle)
	return self
end

--[[---------------------------------------------------------
	- func: SetAngle(angle)
	- desc: sets the object's angle (in degrees), applying snap
			and the min/max limits
--]]---------------------------------------------------------
function newobject:SetAngle(angle)
	angle = angle % 360
	-- snap to the nearest interval
	local snap = self.snap
	if snap and snap > 0 then
		angle = (math.floor(angle / snap + 0.5) * snap) % 360
	end
	-- clamp to the allowed arc
	if angle < self.min then
		angle = self.min
	elseif angle > self.max then
		angle = self.max
	end
	local changed = angle ~= self.angle
	self.angle = angle
	if changed then
		local onvaluechanged = self.OnValueChanged
		if onvaluechanged then
			onvaluechanged(self, angle)
		end
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetAngle()
	- desc: gets the object's angle (in degrees)
--]]---------------------------------------------------------
function newobject:GetAngle()
	return self.angle
end

newobject.SetValue = newobject.SetAngle
newobject.GetValue = newobject.GetAngle

--[[---------------------------------------------------------
	- func: SetMinMax(min, max)
	- desc: sets the minimum and maximum angle (in degrees)
--]]---------------------------------------------------------
function newobject:SetMinMax(min, max)
	self.min = min
	self.max = max
	self:SetAngle(self.angle)
	return self
end

--[[---------------------------------------------------------
	- func: GetMinMax()
	- desc: gets the minimum and maximum angle
--]]---------------------------------------------------------
function newobject:GetMinMax()
	return self.min, self.max
end

--[[---------------------------------------------------------
	- func: SetSnap(snap)
	- desc: sets the snap interval in degrees (0 = no snapping)
--]]---------------------------------------------------------
function newobject:SetSnap(snap)
	self.snap = snap
	self:SetAngle(self.angle)
	return self
end

--[[---------------------------------------------------------
	- func: GetSnap()
	- desc: gets the snap interval in degrees
--]]---------------------------------------------------------
function newobject:GetSnap()
	return self.snap
end

--[[---------------------------------------------------------
	- func: SetEnabled(bool)
	- desc: sets whether or not the object is enabled
--]]---------------------------------------------------------
function newobject:SetEnabled(bool)
	self.enabled = bool
	return self
end

--[[---------------------------------------------------------
	- func: GetEnabled()
	- desc: gets whether or not the object is enabled
--]]---------------------------------------------------------
function newobject:GetEnabled()
	return self.enabled
end

---------- module end ----------
end
