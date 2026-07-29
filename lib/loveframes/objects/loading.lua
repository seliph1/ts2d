return function(loveframes)
	---------- module start ----------

	local newobject = loveframes.NewObject("loading", "loveframes_object_loading", true)

	function newobject:initialize()
		self.type = "loading"
		self.width = 40
		self.height = 40
		self.internal = false
		self.speed = math.pi * 3 -- 1.5 rotations per second
		self.angle = 0
		self.radius = 15

		self:SetDrawFunc()
	end

	function newobject:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		local parent = self.parent
		local base = loveframes.base

		self:CheckHover()

		self.angle = self.angle + self.speed * dt
		if self.angle >= math.pi * 2 then
			self.angle = self.angle - math.pi * 2
		end

		-- move to parent if there is a parent
		if parent ~= base then
			self.x = self.parent.x + self.staticx
			self.y = self.parent.y + self.staticy
		end

		if self.Update then
			self:Update(dt)
		end
	end

	function newobject:SetRadius(radius)
		self.radius = radius
		self.width = radius * 2
		self.height = radius * 2
		return self
	end

	function newobject:GetRadius()
		return self.radius
	end

	function newobject:SetSpeed(speed)
		self.speed = speed
		return self
	end

	function newobject:GetSpeed()
		return self.speed
	end

	function newobject:GetAngle()
		return self.angle
	end

	return newobject

	---------- module end ----------
end
