--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- Container object for subset of love graphics
local Container = loveframes.NewObject("container", "loveframes_object_container", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function Container:initialize()
	self.type = "container"
	self.container = false
	self.width = 200
	self.height = 50
	self.internal = false
	self.children = {}
	self.internals = {}
	--self.collide = false
	self.OnControlKeyPressed = nil
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the element
--]]---------------------------------------------------------
function Container:update(dt)
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
	for k, v in pairs(children) do
		v:update(dt)
	end
	for k,v in pairs(internals) do
		v:update(dt)
	end
 	if update then
		update(self, dt)
	end
end

function Container:keypressed(key)
	if not self:OnState() then return end
	if self.OnControlKeyPressed then
		self.OnControlKeyPressed(self, key, true)
	end
	if not self:isUpdating() then return end
	Container.super.keypressed(self, key)
end

function Container:keyreleased(key)
	if not self:OnState() then return end
	if self.OnControlKeyPressed then
		self.OnControlKeyPressed(self, key, false)
	end
	if not self:isUpdating() then return end
	Container.super.keyreleased(self, key)
end

function Container:wheelmoved(x, y)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local scroll = self.Scroll
	if scroll then
		scroll(self, x, y)
	end

	Container.super.wheelmoved(self, x, y)
end

function Container:mousepressed(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local onmousepressed = self.OnMousePressed
	if onmousepressed then
		onmousepressed(self, x, y, button)
	end

	Container.super.mousepressed(self, x, y, button)
end

function Container:mousemoved(x, y)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	Container.super.mousemoved(self, x, y)
end

function Container:draw()
	if not self:OnState() then return end
	if not self:IsVisible() then return end

	local drawfunc = self.Draw or self.drawfunc
	if drawfunc then
		drawfunc(self)
	end

	Container.super.draw(self)
end
---------- module end ----------
end
