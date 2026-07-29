--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- graphsocket object (created internally)
	local newobject = loveframes.NewObject("graphsocket", "loveframes_object_graphsocket", true)
	loveframes.objects["graphsocket"] = nil
	loveframes.graphsocket = newobject

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function newobject:initialize()
		self.type = "graphsocket"
		self.width = 12
		self.height = 12
		self.sockettype = "input" -- "input" or "output"
		self.datatype = "any"
		self.color = { 1, 1, 1, 1 }
		self.name = "Socket"
		self.internal = false
		self.internals = {}
		self.collide = true

		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: GetGraphField()
	- desc: climbs up the hierarchy to find the graphfield
--]] ---------------------------------------------------------
	function newobject:GetGraphField()
		local p = self.parent
		while p do
			if p.type == "graphfield" then
				return p
			end
			p = p.parent
		end
		return nil
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: handles click events to start connection dragging or disconnect
--]] ---------------------------------------------------------
	function newobject:mousepressed(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		if button == 1 and self.hover then
			local gf = self:GetGraphField()
			if gf then
				-- Bring parent node to top of graphfield
				if self.parent and self.parent.type == "graphnode" then
					self.parent:MoveToTop()
				end
				gf:StartConnecting(self)
			end
		elseif button == 2 and self.hover then
			local gf = self:GetGraphField()
			if gf then
				if self.sockettype == "input" then
					gf:DisconnectInput(self)
				else
					gf:DisconnectOutput(self)
				end
			end
		end
	end

	--[[---------------------------------------------------------
	- func: update(dt)
	- desc: updates the position relative to the parent node
--]] ---------------------------------------------------------
	function newobject:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		self:CheckHover()

		local parent = self.parent
		local base = loveframes.base
		if parent and parent ~= base then
			self.x = parent.x + self.staticx
			self.y = parent.y + self.staticy
		end
	end

	---------- module end ----------
end
