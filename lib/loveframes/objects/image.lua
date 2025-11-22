--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- image object
local newobject = loveframes.NewObject("image", "loveframes_object_image", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()

	self.type = "image"
	self.width = 50
	self.height = 50
	self.orientation = 0
	self.scalex = 1
	self.scaley = 1
	self.offsetx = 0
	self.offsety = 0
	self.shearx = 0
	self.sheary = 0
	self.internal = false
	self.image = nil
	self.imagecolor = {1, 1, 1, 1}
	self.centered = false
	
	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function newobject:update(dt)
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
	if update then
		update(self, dt)
	end
end

--[[---------------------------------------------------------
	- func: SetImage(image)
	- desc: sets the object's image
--]]---------------------------------------------------------
function newobject:SetImage(image)
	if type(image) == "string" then
		self.image = love.graphics.newImage(image)
		self.image:setFilter("nearest", "nearest")
	elseif type(image) == "userdata" and tostring(image):find("ImageData") then
		self.image = love.graphics.newImage(image)
	else
		self.image = image
	end
	self:SetSize( self.image:getWidth(), self.image:getHeight())
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
	self.imagecolor[1] = r or self.imagecolor[1]
	self.imagecolor[2] = g or self.imagecolor[2]
	self.imagecolor[3] = b or self.imagecolor[3]
	self.imagecolor[4] = a or self.imagecolor[4]
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
	- func: SetCentered(bool)
	- desc: sets if the image should be rendered at center
--]]---------------------------------------------------------
function newobject:SetCentered(bool)
	self.centered = bool
	return self
end
---------- module end ----------
end