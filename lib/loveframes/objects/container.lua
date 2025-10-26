--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- panel object
local newobject = loveframes.NewObject("container", "loveframes_object_container", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	self.type = "container"
	self.container = false
	self.width = 200
	self.height = 50
	self.internal = false
	self.children = {}
	self.internals = {}
	--self.collide = false
	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the element
--]]---------------------------------------------------------
function newobject:update(dt)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local children = self.children
	local internals = self.internals
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update
	-- move to parent if there is a parent
	if parent ~= base then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end
	self:CheckHover()
	for k, v in ipairs(children) do
		v:update(dt)
	end
	for k,v in ipairs(internals) do
		v:update(dt)
	end
 	if update then
		update(self, dt)
	end
end
---------- module end ----------
end
