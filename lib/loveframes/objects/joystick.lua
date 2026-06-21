--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

--[[------------------------------------------------
	-- joystick: a virtual analog stick. A round base
	-- with a draggable knob; the knob can be pushed in
	-- any direction up to the base radius and reports a
	-- normalized vector (vx, vy) in [-1, 1] (y grows
	-- downward, screen-style). On release the knob eases
	-- back to the center unless autocenter is off.
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- joystick object
local newobject = loveframes.NewObject("joystick", "loveframes_object_joystick", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()

	self.type = "joystick"
	self.width = 120
	self.height = 120
	self.knobsize = 36          -- knob diameter
	self.deadzone = 0.1         -- magnitude below this reports zero
	self.autocenter = true      -- ease the knob back to center on release
	self.returnspeed = 14       -- easing speed of the auto-center
	self.enabled = true
	self.dragging = false
	self.internal = false
	self.internals = {}

	-- normalized output, [-1, 1]
	self.vx = 0
	self.vy = 0
	-- knob offset from the center, in pixels (for drawing)
	self.knobx = 0
	self.knoby = 0

	self.OnValueChanged = nil
	self.OnRelease = nil

	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: GetBaseRadius() / GetMaxDistance()
	- desc: the base radius and how far the knob center may
			travel from the center (kept inside the base)
--]]---------------------------------------------------------
function newobject:GetBaseRadius()
	return math.min(self.width, self.height) / 2
end

function newobject:GetMaxDistance()
	return math.max(1, self:GetBaseRadius() - self.knobsize / 2)
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

	if self.dragging and self.enabled then
		-- follow the mouse even when it leaves the base
		local mx, my = love.mouse.getPosition()
		self:SetVectorFromPos(mx, my)
	elseif self.autocenter and (self.knobx ~= 0 or self.knoby ~= 0) then
		-- ease the knob back toward the center
		local t = math.min(1, self.returnspeed * dt)
		local nx = self.knobx + (0 - self.knobx) * t
		local ny = self.knoby + (0 - self.knoby) * t
		if math.abs(nx) < 0.5 and math.abs(ny) < 0.5 then
			nx, ny = 0, 0
		end
		self:SetKnob(nx, ny)
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
	- desc: returns whether the given point is within the base
--]]---------------------------------------------------------
function newobject:IsInsideCircle(x, y)
	local radius = self:GetBaseRadius()
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
		self:SetVectorFromPos(x, y)
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
		if not self.autocenter then
			-- leave the knob where it is
		end
		local onrelease = self.OnRelease
		if onrelease then
			onrelease(self, self.vx, self.vy)
		end
	end

	for k, v in ipairs(self.internals) do
		v:mousereleased(x, y, button)
	end
end

--[[---------------------------------------------------------
	- func: SetVectorFromPos(mx, my)
	- desc: positions the knob from a point (e.g. the mouse),
			clamped to the base, and updates the output vector
--]]---------------------------------------------------------
function newobject:SetVectorFromPos(mx, my)
	local cx = self.x + self.width / 2
	local cy = self.y + self.height / 2
	local dx = mx - cx
	local dy = my - cy
	local maxdist = self:GetMaxDistance()
	local dist = math.sqrt(dx * dx + dy * dy)
	if dist > maxdist and dist > 0 then
		dx = dx / dist * maxdist
		dy = dy / dist * maxdist
	end
	self:SetKnob(dx, dy)
	return self
end

--[[---------------------------------------------------------
	- func: SetKnob(dx, dy)
	- desc: (internal) sets the knob's pixel offset and derives
			the normalized vector, applying the deadzone and
			firing OnValueChanged when the output changes
--]]---------------------------------------------------------
function newobject:SetKnob(dx, dy)
	self.knobx = dx
	self.knoby = dy

	local maxdist = self:GetMaxDistance()
	local vx = dx / maxdist
	local vy = dy / maxdist

	-- deadzone on the resulting magnitude
	local mag = math.sqrt(vx * vx + vy * vy)
	if mag < self.deadzone then
		vx, vy = 0, 0
	end

	local changed = (vx ~= self.vx) or (vy ~= self.vy)
	self.vx = vx
	self.vy = vy
	if changed then
		local onvaluechanged = self.OnValueChanged
		if onvaluechanged then
			onvaluechanged(self, vx, vy)
		end
	end
	return self
end

--[[---------------------------------------------------------
	- func: Center()
	- desc: snaps the knob back to the center (output zero)
--]]---------------------------------------------------------
function newobject:Center()
	self:SetKnob(0, 0)
	return self
end

--[[---------------------------------------------------------
	- func: GetValue() / GetX() / GetY()
	- desc: the normalized output vector, each axis in [-1, 1]
--]]---------------------------------------------------------
function newobject:GetValue()
	return self.vx, self.vy
end

function newobject:GetX()
	return self.vx
end

function newobject:GetY()
	return self.vy
end

--[[---------------------------------------------------------
	- func: GetMagnitude()
	- desc: how far the stick is pushed, in [0, 1]
--]]---------------------------------------------------------
function newobject:GetMagnitude()
	local mag = math.sqrt(self.vx * self.vx + self.vy * self.vy)
	if mag > 1 then mag = 1 end
	return mag
end

--[[---------------------------------------------------------
	- func: GetAngle()
	- desc: direction in degrees, 0 = up, increasing clockwise.
			Returns nil when centered (no direction)
--]]---------------------------------------------------------
function newobject:GetAngle()
	if self.vx == 0 and self.vy == 0 then
		return nil
	end
	local angle = math.deg(math.atan2(self.vx, -self.vy))
	if angle < 0 then
		angle = angle + 360
	end
	return angle
end

--[[---------------------------------------------------------
	- func: GetDirection4() / GetDirection8()
	- desc: the pushed direction as a string ("up"/"down"/
			"left"/"right"[/diagonals]), or nil when centered
--]]---------------------------------------------------------
function newobject:GetDirection4()
	local angle = self:GetAngle()
	if not angle then return nil end
	if angle >= 315 or angle < 45 then return "up"
	elseif angle < 135 then return "right"
	elseif angle < 225 then return "down"
	else return "left" end
end

function newobject:GetDirection8()
	local angle = self:GetAngle()
	if not angle then return nil end
	local dirs = {"up", "upright", "right", "downright", "down", "downleft", "left", "upleft"}
	local index = math.floor((angle + 22.5) / 45) % 8 + 1
	return dirs[index]
end

--[[---------------------------------------------------------
	- func: SetDeadzone(value) / GetDeadzone()
	- desc: magnitude (0..1) below which the output is zeroed
--]]---------------------------------------------------------
function newobject:SetDeadzone(value)
	self.deadzone = value
	return self
end

function newobject:GetDeadzone()
	return self.deadzone
end

--[[---------------------------------------------------------
	- func: SetAutoCenter(bool) / GetAutoCenter()
	- desc: whether the knob eases back to center on release
--]]---------------------------------------------------------
function newobject:SetAutoCenter(bool)
	self.autocenter = bool
	return self
end

function newobject:GetAutoCenter()
	return self.autocenter
end

--[[---------------------------------------------------------
	- func: SetReturnSpeed(speed) / GetReturnSpeed()
	- desc: easing speed of the auto-center (higher is snappier)
--]]---------------------------------------------------------
function newobject:SetReturnSpeed(speed)
	self.returnspeed = speed
	return self
end

function newobject:GetReturnSpeed()
	return self.returnspeed
end

--[[---------------------------------------------------------
	- func: SetKnobSize(size) / GetKnobSize()
	- desc: the knob diameter, in pixels
--]]---------------------------------------------------------
function newobject:SetKnobSize(size)
	self.knobsize = size
	return self
end

function newobject:GetKnobSize()
	return self.knobsize
end

--[[---------------------------------------------------------
	- func: SetEnabled(bool) / GetEnabled()
	- desc: sets whether or not the object is enabled
--]]---------------------------------------------------------
function newobject:SetEnabled(bool)
	self.enabled = bool
	if not bool then
		self.dragging = false
		self:Center()
	end
	return self
end

function newobject:GetEnabled()
	return self.enabled
end

---------- module end ----------
end
