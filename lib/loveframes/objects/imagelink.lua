--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- image object
local newobject = loveframes.NewObject("imagelink", "loveframes_object_imagelink", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()

	self.type = "imagelink"
	self.width = 0
	self.height = 0
	self.orientation = 0
	self.scalex = 1
	self.scaley = 1
	self.offsetx = 0
	self.offsety = 0
	self.shearx = 0
	self.sheary = 0
	self.internal = false
	self.clickable = true
	self.enabled = true
	self.image = nil
	self.checked = false
	self.imagecolor = {1, 1, 1, 1}
	
	self.groupIndex = 0
	self.OnClick = nil
	
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
	
	local hover = self.hover
	local downobject = loveframes.downobject
	local down = self.down
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update
	
	if not hover then
		self.down = false
	else
		if downobject == self then
			self.down = true
		end
	end
	
	if not down and downobject == self then
		self.hover = true
	end
	
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
		local baseparent = self:GetBaseParent()
		if baseparent and baseparent.type == "frame" then
			baseparent:MakeTop()
		end
		self.down = true
		loveframes.downobject = self
	end
	
end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function newobject:mousereleased(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local hover = self.hover
	local down = self.down
	local clickable = self.clickable
	local enabled = self.enabled
	local onclick = self.OnClick

	if hover and down and clickable and button == 1 then
		if enabled then
			if self.groupIndex ~= 0 then
				local baseparent = self.parent
				if baseparent then
					for k, v in ipairs(baseparent.children) do
						if v.groupIndex then
							if v.groupIndex == self.groupIndex then
								v.checked = false
							end
						end
					end
				end
				self.checked = true
			end
			if onclick then
				onclick(self, x, y)
			end
		end
	end
	
	self.down = false
end

--[[---------------------------------------------------------
	- func: SetImage(image)
	- desc: sets the object's image
--]]---------------------------------------------------------
function newobject:SetImage(image)

	if type(image) == "string" then
		self.image = love.graphics.newImage(image)
		self.image:setFilter("nearest", "nearest")
	else
		self.image = image
	end
	
	self.width = self.image:getWidth()
	self.height = self.image:getHeight()
	
	return self
	
end

--[[---------------------------------------------------------
	- func: GetImage()
	- desc: gets the object's image
--]]---------------------------------------------------------
function newobject:GetImage()

	return self.image
	
end

--[[---------------------------------------------------------
	- func: SetColor(r, g, b, a)
	- desc: sets the object's color 
--]]---------------------------------------------------------
function newobject:SetColor(r, g, b, a)

	self.imagecolor = {r, g, b, a}
	return self
	
end

--[[---------------------------------------------------------
	- func: GetColor()
	- desc: gets the object's color 
--]]---------------------------------------------------------
function newobject:GetColor()

	return unpack(self.imagecolor)
	
end

--[[---------------------------------------------------------
	- func: SetOrientation(orientation)
	- desc: sets the object's orientation
--]]---------------------------------------------------------
function newobject:SetOrientation(orientation)

	self.orientation = orientation
	return self
	
end

--[[---------------------------------------------------------
	- func: GetOrientation()
	- desc: gets the object's orientation
--]]---------------------------------------------------------
function newobject:GetOrientation()

	return self.orientation
	
end

--[[---------------------------------------------------------
	- func: SetScaleX(scalex)
	- desc: sets the object's x scale
--]]---------------------------------------------------------
function newobject:SetScaleX(scalex)

	self.scalex = scalex
	return self
	
end

--[[---------------------------------------------------------
	- func: GetScaleX()
	- desc: gets the object's x scale
--]]---------------------------------------------------------
function newobject:GetScaleX()

	return self.scalex
	
end

--[[---------------------------------------------------------
	- func: SetScaleY(scaley)
	- desc: sets the object's y scale
--]]---------------------------------------------------------
function newobject:SetScaleY(scaley)

	self.scaley = scaley
	return self
	
end

--[[---------------------------------------------------------
	- func: GetScaleY()
	- desc: gets the object's y scale
--]]---------------------------------------------------------
function newobject:GetScaleY()

	return self.scaley
	
end

--[[---------------------------------------------------------
	- func: SetScale(scalex, scaley)
	- desc: sets the object's x and y scale
--]]---------------------------------------------------------
function newobject:SetScale(scalex, scaley)

	self.scalex = scalex
	self.scaley = scaley
	
	return self
	
end

--[[---------------------------------------------------------
	- func: GetScale()
	- desc: gets the object's x and y scale
--]]---------------------------------------------------------
function newobject:GetScale()

	return self.scalex, self.scaley
	
end

--[[---------------------------------------------------------
	- func: SetOffsetX(x)
	- desc: sets the object's x offset
--]]---------------------------------------------------------
function newobject:SetOffsetX(x)

	self.offsetx = x
	return self
	
end

--[[---------------------------------------------------------
	- func: GetOffsetX()
	- desc: gets the object's x offset
--]]---------------------------------------------------------
function newobject:GetOffsetX()

	return self.offsetx
	
end

--[[---------------------------------------------------------
	- func: SetOffsetY(y)
	- desc: sets the object's y offset
--]]---------------------------------------------------------
function newobject:SetOffsetY(y)

	self.offsety = y
	return self
	
end

--[[---------------------------------------------------------
	- func: GetOffsetY()
	- desc: gets the object's y offset
--]]---------------------------------------------------------
function newobject:GetOffsetY()

	return self.offsety
	
end

--[[---------------------------------------------------------
	- func: SetOffset(x, y)
	- desc: sets the object's x and y offset
--]]---------------------------------------------------------
function newobject:SetOffset(x, y)

	self.offsetx = x
	self.offsety = y
	
	return self
	
end

--[[---------------------------------------------------------
	- func: GetOffset()
	- desc: gets the object's x and y offset
--]]---------------------------------------------------------
function newobject:GetOffset()

	return self.offsetx, self.offsety
	
end

--[[---------------------------------------------------------
	- func: SetShearX(shearx)
	- desc: sets the object's x shear
--]]---------------------------------------------------------
function newobject:SetShearX(shearx)

	self.shearx = shearx
	return self
	
end

--[[---------------------------------------------------------
	- func: GetShearX()
	- desc: gets the object's x shear
--]]---------------------------------------------------------
function newobject:GetShearX()

	return self.shearx
	
end

--[[---------------------------------------------------------
	- func: SetShearY(sheary)
	- desc: sets the object's y shear
--]]---------------------------------------------------------
function newobject:SetShearY(sheary)

	self.sheary = sheary
	return self
	
end

--[[---------------------------------------------------------
	- func: GetShearY()
	- desc: gets the object's y shear
--]]---------------------------------------------------------
function newobject:GetShearY()

	return self.sheary
	
end

--[[---------------------------------------------------------
	- func: SetShear(shearx, sheary)
	- desc: sets the object's x and y shear
--]]---------------------------------------------------------
function newobject:SetShear(shearx, sheary)

	self.shearx = shearx
	self.sheary = sheary
	
	return self
	
end

--[[---------------------------------------------------------
	- func: GetShear()
	- desc: gets the object's x and y shear
--]]---------------------------------------------------------
function newobject:GetShear()

	return self.shearx, self.sheary
	
end

--[[---------------------------------------------------------
	- func: GetImageSize()
	- desc: gets the size of the object's image
--]]---------------------------------------------------------
function newobject:GetImageSize()

	local image = self.image
	
	if image then
		return image:getWidth(), image:getHeight()
	end
	
end

--[[---------------------------------------------------------
	- func: GetImageWidth()
	- desc: gets the width of the object's image
--]]---------------------------------------------------------
function newobject:GetImageWidth()

	local image = self.image
	
	if image then
		return image:getWidth()
	end
	
end

--[[---------------------------------------------------------
	- func: GetImageWidth()
	- desc: gets the height of the object's image
--]]---------------------------------------------------------
function newobject:GetImageHeight()

	local image = self.image
	
	if image then
		return image:getHeight()
	end
	
end

--[[---------------------------------------------------------
	- func: SetClickable(bool)
	- desc: sets whether the object can be clicked or not
--]]---------------------------------------------------------
function newobject:SetClickable(bool)

	self.clickable = bool
	return self
	
end

--[[---------------------------------------------------------
	- func: GetClickable(bool)
	- desc: gets whether the object can be clicked or not
--]]---------------------------------------------------------
function newobject:GetClickable()

	return self.clickable
	
end

--[[---------------------------------------------------------
	- func: SetClickable(bool)
	- desc: sets whether the object is enabled or not
--]]---------------------------------------------------------
function newobject:SetEnabled(bool)

	self.enabled = bool
	return self
	
end

--[[---------------------------------------------------------
	- func: GetEnabled()
	- desc: gets whether the object is enabled or not
--]]---------------------------------------------------------
function newobject:GetEnabled()

	return self.enabled
	
end



---------- module end ----------
end
