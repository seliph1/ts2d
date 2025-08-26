--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- button object
local newobject = loveframes.NewObject("treenodebutton", "loveframes_object_treenodebutton", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	
	self.type = "treenodebutton"
	self.width = 16
	self.height = 16
	self.internal = true
	
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
	
	if update then
		update(self, dt)
	end

end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local hover = self.hover
	
	if hover and button == 1 then
		local bool = not self.parent.open
		if bool then
			local onopen = self.parent.OnOpen
			if onopen then
				onopen(self.parent)
			end
		else
			local onclose = self.parent.OnClose
			if onclose then
				onclose(self.parent)
			end
		end
		self.parent:SetOpen(bool)
		print("!")
		print(self.parent.level)
	end
	
end

---------- module end ----------
end
