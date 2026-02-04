--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- base object
local Base = loveframes.NewObject("base", "loveframes_object_base")

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the element
--]]---------------------------------------------------------
function Base:initialize()
	self.type = "base"
	self.width, self.height = love.graphics.getDimensions()
	self.internal = true
	self.children = {}
	self.internals = {}
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function Base:update(dt)
	if not self:OnState() then return end
	local children = self.children
	if children then
		for k, v in pairs(children) do
			v:update(dt)
		end
	end
	local internals = self.internals
	if internals then
		for k, v in pairs(internals) do
			v:update(dt)
		end
	end
end

function Base:UpdateZero()
	local state = self.state
	local visible = self.visible
	self.state = "*"
	self.visible = true
	--//------------------
	self:update(0)
	--//------------------
	self.state = state
	self.visible = visible
end

--[[---------------------------------------------------------
	- func: draw()
	- desc: draws the object
--]]---------------------------------------------------------
function Base:draw()
	if not self:OnState() then return end
	if not self:IsVisible() then return end

	self:SetDrawOrder()
	local drawfunc = self.Draw or self.drawfunc
	if drawfunc then
		drawfunc(self)
	end
	local children = self.children
	if children then
		for k, v in pairs(children) do
			v:draw()
		end
	end
	local internals = self.internals
	if internals then
		for k, v in pairs(internals) do
			v:draw()
		end
	end
	drawfunc = self.DrawOver or self.drawoverfunc
	if drawfunc then
		drawfunc(self)
	end
end

--[[---------------------------------------------------------
	- func: mousemoved(x, y, button)
	- desc: called when the player moves mouse
--]]---------------------------------------------------------
function Base:mousemoved(x, y, dx, dy, istouch)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local children = self.children
	if children then
		for k, v in pairs(children) do
			v:mousemoved(x, y, dx, dy, istouch)
		end
	end
	local internals = self.internals
	if internals then
		for k, v in pairs(internals) do
			v:mousemoved(x, y, dx, dy, istouch)
		end
	end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function Base:mousepressed(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local children = self.children
	if children then
		for k, v in pairs(children) do
			v:mousepressed(x, y, button)
		end
	end

	local internals = self.internals
	if internals then
		for k, v in pairs(internals) do
			v:mousepressed(x, y, button)
		end
	end
end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function Base:mousereleased(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local children = self.children
	if children then
		for k, v in pairs(children) do
			v:mousereleased(x, y, button)
		end
	end
	local internals = self.internals
	if internals then
		for k, v in pairs(internals) do
			v:mousereleased(x, y, button)
		end
	end
end

--[[---------------------------------------------------------
	- func: wheelmoved(x, y)
	- desc: called when the player moves a mouse wheel
--]]---------------------------------------------------------
function Base:wheelmoved(x, y)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local children = self.children
	if children then
		for k, v in pairs(children) do
			v:wheelmoved(x, y)
		end
	end
	local internals = self.internals
	if internals then
		for k, v in pairs(internals) do
			v:wheelmoved(x, y)
		end
	end
end

--[[---------------------------------------------------------
	- func: keypressed(key, isrepeat)
	- desc: called when the player presses a key
--]]---------------------------------------------------------
function Base:keypressed(key, isrepeat)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local children = self.children
	if children then
		for k, v in pairs(children) do
			v:keypressed(key, isrepeat)
		end
	end
	local internals = self.internals
	if internals then
		for k, v in pairs(internals) do
			v:keypressed(key, isrepeat)
		end
	end
end

--[[---------------------------------------------------------
	- func: keyreleased(key)
	- desc: called when the player releases a key
--]]---------------------------------------------------------
function Base:keyreleased(key)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local children = self.children
	if children then
		for k, v in pairs(children) do
			v:keyreleased(key)
		end
	end
	local internals = self.internals
	if internals then
		for k, v in pairs(internals) do
			v:keyreleased(key)
		end
	end
end
--[[---------------------------------------------------------
	- func: textinput(text)
	- desc: called when the user inputs text
--]]---------------------------------------------------------
function Base:textinput(text)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local children = self.children
	if children then
		for k, v in pairs(children) do
			v:textinput(text)
		end
	end
	local internals = self.internals
	if internals then
		for k, v in pairs(internals) do
			v:textinput(text)
		end
	end
end
--[[---------------------------------------------------------
	- func: SetPos(x, y, center)
	- desc: sets the object's position
--]]---------------------------------------------------------
function Base:SetPos(x, y, center)
	local base = loveframes.base
	local parent = self.parent

	if math.abs(x) >= 0 and math.abs(x) < 1 then
		x = self.parent.width * x
	end
	if math.abs(y) >= 0 and math.abs(y) < 1 then
		y = self.parent.height * y
	end

	if x < 0 then x = self.parent.width - self.width - math.abs(x) end
	if y < 0 then y = self.parent.height - self.height - math.abs(y) end
	if center then
		x = x - self.width/2
		y = y - self.height/2
	end
	if parent == base then
		self.x = math.floor(x)
		self.y = math.floor(y)
	else
		self.staticx = math.floor(x)
		self.staticy = math.floor(y)
	end

	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end

function Base:SetAbsolutePos(x, y, center)
	local base = loveframes.base
	local parent = self.parent

	if math.abs(x) >= 0 and math.abs(x) < 1 then
		x = self.parent.width * x
	end
	if math.abs(y) >= 0 and math.abs(y) < 1 then
		y = self.parent.height * y
	end

	if x < 0 then x = self.parent.width - self.width - math.abs(x) end
	if y < 0 then y = self.parent.height - self.height - math.abs(y) end
	if center then
		x = x - self.width/2
		y = y - self.height/2
	end
	if parent == base then
		self.x = math.floor(x)
		self.y = math.floor(y)
	else
		self.staticx = math.floor(x - parent.x)
		self.staticy = math.floor(y - parent.y)
	end

	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end

function Base:MoveToParent()
end

--[[---------------------------------------------------------
	- func: SetX(x, center)
	- desc: sets the object's x position
--]]---------------------------------------------------------
function Base:SetX(x, center)
	local base = loveframes.base
	local parent = self.parent
	if math.abs(x) >= 0 and math.abs(x) < 1 then
		x = self.parent.width * x
	end
	if x < 0 then x = self.parent.width - self.width - math.abs(x) end
	if center then x = x - self.width/2	end
	if parent == base then
		self.x = math.floor(x)
	else
		self.staticx = math.floor(x)
	end
	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end
--[[---------------------------------------------------------
	- func: SetY(y, center)
	- desc: sets the object's y position
--]]---------------------------------------------------------
function Base:SetY(y, center)
	local base = loveframes.base
	local parent = self.parent
	if math.abs(y) >= 0 and math.abs(y) < 1 then
		y = self.parent.height * y
	end
	if y < 0 then y = self.parent.height - self.height - math.abs(y) end
	if center then y = y - self.height/2 end
	if parent == base then
		self.y = math.floor(y)
	else
		self.staticy = math.floor(y)
	end
	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end
--[[---------------------------------------------------------
	- func: GetPos()
	- desc: gets the object's position
--]]---------------------------------------------------------
function Base:GetPos()
	return self.x, self.y
end

--[[---------------------------------------------------------
	- func: GetX()
	- desc: gets the object's x position
--]]---------------------------------------------------------
function Base:GetX()
	return self.x
end

--[[---------------------------------------------------------
	- func: GetY()
	- desc: gets the object's y position
--]]---------------------------------------------------------
function Base:GetY()
	return self.y
end

--[[---------------------------------------------------------
	- func: GetStaticPos()
	- desc: gets the object's static position
--]]---------------------------------------------------------
function Base:GetStaticPos()
	return self.staticx, self.staticy
end

--[[---------------------------------------------------------
	- func: GetStaticX()
	- desc: gets the object's static x position
--]]---------------------------------------------------------
function Base:GetStaticX()
	return self.staticx
end

--[[---------------------------------------------------------
	- func: GetStaticY()
	- desc: gets the object's static y position
--]]---------------------------------------------------------
function Base:GetStaticY()
	return self.staticy
end

--[[---------------------------------------------------------
	- func: Center()
	- desc: centers the object in the game window or in
			its parent if it has one
--]]---------------------------------------------------------
function Base:Center()
	local base = loveframes.base
	local parent = self.parent
	if parent == base then
		local width = love.graphics.getWidth()
		local height = love.graphics.getHeight()
		self.x = math.floor( width/2 - self.width * (self.scalex or 1)/2 )
		self.y = math.floor( height/2 - self.height * (self.scaley or 1)/2 )
	else
		local width = parent.width
		local height = parent.height
		self.staticx = math.floor( width/2 - self.width * (self.scalex or 1)/2 )
		self.staticy = math.floor( height/2 - self.height * (self.scaley or 1)/2 )
	end
	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end

--[[---------------------------------------------------------
	- func: CenterX()
	- desc: centers the object by its x value
--]]---------------------------------------------------------
function Base:CenterX()
	local base = loveframes.base
	local parent = self.parent
	if parent == base then
		local width = love.graphics.getWidth()
		self.x = math.floor( width/2 - self.width * (self.scalex or 1)/2 )
	else
		local width = parent.width
		self.staticx = math.floor( width/2 - self.width * (self.scalex or 1)/2 )
	end
	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end

--[[---------------------------------------------------------
	- func: CenterY()
	- desc: centers the object by its y value
--]]---------------------------------------------------------
function Base:CenterY()
	local base = loveframes.base
	local parent = self.parent
	if parent == base then
		local height = love.graphics.getHeight()
		self.y = math.floor( height/2 - self.height * (self.scaley or 1)/2 )
	else
		local height = parent.height
		self.staticy = math.floor( height/2 - self.height * (self.scaley or 1)/2 )
	end
	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end
--[[---------------------------------------------------------
	- func: CenterWithinArea()
	- desc: centers the object within the given area
--]]---------------------------------------------------------
function Base:CenterWithinArea(x, y, width, height)
	local parent = self.parent
	local selfwidth = self.width
	local selfheight = self.height

	if parent == loveframes.base then
		self.x = math.floor(x + width/2 - selfwidth/2)
		self.y = math.floor(y + height/2 - selfheight/2)
	else
		self.staticx = math.floor(x + width/2 - selfwidth/2)
		self.staticy = math.floor(y + height/2 - selfheight/2)
	end

	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end

--[[---------------------------------------------------------
	- func: Align(Direction)
	- desc: Move object to the border of parent
--]]---------------------------------------------------------
function Base:AlignLeft(margin)
	local base = loveframes.base
	local parent = self.parent
	margin = margin or 0
	if margin > 0 and margin < 1 then
		margin = math.floor( margin * parent.width )
	end

	if parent == base then
		self.x = 0 + margin
	else
		self.x = parent.x + margin
	end

	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end

function Base:AlignRight(margin)
	local base = loveframes.base
	local parent = self.parent
	margin = margin or 0
	if margin > 0 and margin < 1 then
		margin = math.floor( margin * parent.width )
	end

	if parent == base then
		self.x = love.graphics.getWidth() - self.width - margin
	else
		self.x = self.width - parent.width + parent.x - margin
	end

	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end

function Base:AlignTop(margin)
	local base = loveframes.base
	local parent = self.parent
	margin = margin or 0
	if margin > 0 and margin < 1 then
		margin = math.floor( margin * parent.height )
	end

	if parent then
		self.y = 0 + margin
	else
		self.y = parent.y + margin
	end

	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end

function Base:AlignBottom(margin)
	local base = loveframes.base
	local parent = self.parent
	margin = margin or 0
	if margin > 0 and margin < 1 then
		margin = math.floor( margin * parent.height )
	end

	if parent then
		self.y = love.graphics.getHeight() - self.height - margin
	else
		self.y = self.height - parent.height + parent.y - margin
	end

	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	return self
end

function Base:AlignChildren(axis, ...)
	local args = {...}
	if #args == 0 then
		args = self.children
	end

	for index, child in pairs(args) do
		if axis == "horizontal" then
			child:CenterY()
		elseif axis == "vertical" then
			child:CenterX()
		end
	end

	if self.RedoLayout then
		self:RedoLayout()
	end
	return self
end

--[[---------------------------------------------------------
	- func: Expand
	- desc: expand the object's size to parent's boundary
--]]---------------------------------------------------------
function Base:Expand(direction, margin)
	margin = margin or 0
	direction = direction or "all"
	local factor = 1
	local offset = 0
	if margin > 0 and margin < 1 then
		factor = margin
	else
		offset = margin
	end

	local parent = self.parent
	local base = loveframes.base
	local x, y
	if parent == base then
		x, y = self.x, self.y
	else
		x, y = self.staticx, self.staticy
	end
	-- Reduce the size of object
	direction = string.lower(direction)
	if direction == "right" then
		self.width =  math.floor( (parent.width - x) * factor)  - offset
	elseif direction == "down" or direction == "bottom" then
		self.height = math.floor( (parent.height - y) * factor) - offset
	elseif direction == "left" then
		self.width = math.floor( (self.width + self.x - parent.x) * factor) - offset
		if parent == base then
			self.x = 0
		else
			self.staticx = 0
		end
	elseif direction == "up" or direction == "top" then
		self.height = math.floor( (self.height + self.y - parent.y) * factor) - offset
		if parent == base then
			self.y = 0
		else
			self.staticy = 0
		end
	elseif direction == "all" then
		local offset_x = math.floor( parent.width * (1 - factor) * 0.5 )
		local offset_y = math.floor( parent.height * (1 - factor) * 0.5 )
		if parent == base then
			self.x = offset_x
			self.y = offset_y
		else
			self.staticx = offset_x
			self.staticy = offset_y
		end

		self.width = math.floor( parent.width * factor )
		self.height = math.floor( parent.height * factor )

	end
	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	if self.RedoLayout then
		self:RedoLayout()
	end
	return self
end

function Base:ExpandTo(object, axis, margin)
	if not object then return self end
	local width, height = object.width, object.height
	local x, y
	if object.parent == loveframes.base then
		x, y = object.x, object.y
	else
		x, y = object.staticx, object.staticy
	end
	margin = margin or 0
	local factor = 1
	local offset = 0
	if margin > 0 and margin < 1 then
		factor = margin
	else
		offset = margin
	end

	local offset_x = math.floor( width * (1 - factor) * 0.5 )
	local offset_y = math.floor( height * (1 - factor) * 0.5 )

	if axis == "horizontal" then
		self.width = math.floor((width * factor) - offset)
		if self.parent == loveframes.base then
			self.x = x + offset_x
		else
			self.staticx = x + offset_x
		end
	elseif axis == "vertical" then
		self.height = math.floor((height * factor) - offset)
		if self.parent == loveframes.base then
			self.y = y + offset_y
		else
			self.staticy = y + offset_y
		end
	end
	if self.RedoLayout then
		self:RedoLayout()
	end
	return self
end

--[[---------------------------------------------------------
	- func: Spread(align, elements..)
	- desc: spreds children evenly along the container's length
--]]---------------------------------------------------------
function Base:Spread(align, ...)
	local args = {...}
	if #args == 0 then
		args = self.children
	end
	local gaps = #args + 1 -- Count gaps between children and the start/end border
	local totalwidth = 0
	local totalheight = 0

	-- First pass: sum all child width/height sizes
	for index, element in pairs(args) do
		totalwidth = totalwidth + element:GetWidth()
		totalheight = totalheight + element:GetHeight()
	end

	-- Second pass: position elements
	if align == "horizontal" then
		local remaining = self:GetWidth() - totalwidth
		local gapsize = math.floor(remaining/gaps)
		local gap = 0
		
		for index, element in pairs(args) do
			gap = gap + gapsize
			element:SetX(gap)
			gap = gap + element:GetWidth()
		end
	elseif align == "vertical" then
		local remaining = self:GetHeight() - totalheight
		local gapsize = math.floor(remaining/gaps)
		local gap = 0
		-- Second pass: position elements
		for index, element in pairs(args) do
			gap = gap + gapsize
			element:SetY(gap)
			gap = gap + element:GetHeight()
		end
	end
	if self.RedoLayout then
		self:RedoLayout()
	end
	return self
end

--[[---------------------------------------------------------
	- func: Wrap(align, elements..)
	- desc: Resize object's width and height to accomodate all children
--]]---------------------------------------------------------
function Base:Wrap(margin)
	local maxwidth = 0
	local maxheight = 0
	margin = margin or 0
	if self.children then
		for index, child in pairs(self.children) do
			local width_diff = child:GetStaticX() - self.x + child.width
			local height_diff = child:GetStaticY() - self.y + child.height

			print(width_diff, height_diff)
			if width_diff > self.width then
				maxwidth = width_diff
			end

			if height_diff > self.height then
				maxheight = height_diff
			end
		end
	end

	if maxwidth > self.width then
		self:SetWidth(maxwidth + math.max(margin, 0))
	end

	if maxheight > self.height then
		self:SetHeight(maxheight + math.max(margin, 0))
	end
end

--[[---------------------------------------------------------
	- func: Centralize(align, elements..)
	- desc: Centralizes children evenly along the container's length
--]]---------------------------------------------------------
function Base:Centralize(align, ...)
	return self
end

--[[---------------------------------------------------------
	- func: SetSize(width, height, r1, r2)
	- desc: sets the object's size
--]]---------------------------------------------------------
function Base:SetSize(width, height)
	local parent = self.parent
	if not height then
		height = width
	end
	if width >= 0 and width <= 1 then
		width = self.parent.width * width
	end
	if height >= 0 and height <= 1 then
		height = self.parent.height * height
	end
	self.width = math.floor(width)
	self.height = math.floor(height)

	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	if self.RedoLayout then
		self:RedoLayout()
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetWidth(width, relative)
	- desc: sets the object's width
--]]---------------------------------------------------------
function Base:SetWidth(width)
	local parent = self.parent
	if width >= 0 and width <= 1 then
		width = self.parent.width * width
	end
	self.width = math.floor(width)
	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end

	if self.RedoLayout then
		self:RedoLayout()
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetHeight(height, relative)
	- desc: sets the object's height
--]]---------------------------------------------------------
function Base:SetHeight(height)
	local parent = self.parent
	if height >= 0 and height <= 1 then
		height = self.parent.height * height
	end
	self.height = math.floor(height)
	if parent.container and parent.RedoLayout then
		parent:RedoLayout()
	end
	if self.RedoLayout then
		self:RedoLayout()
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetSize()/GetDimensions
	- desc: gets the object's size
--]]---------------------------------------------------------
function Base:GetSize(padding)
	if padding then
		return self.width - padding, self.height - padding
	else
		return self.width, self.height
	end
end
Base.GetDimensions = Base.GetSize

--[[---------------------------------------------------------
	- func: GetWidth()
	- desc: gets the object's width
--]]---------------------------------------------------------
function Base:GetWidth(padding)
	if padding then
		return self.width - padding
	else
		return self.width
	end
end

--[[---------------------------------------------------------
	- func: GetHeight()
	- desc: gets the object's height
--]]---------------------------------------------------------
function Base:GetHeight(padding)
	if padding then
		return self.height - padding
	else
		return self.height
	end
end

--[[---------------------------------------------------------
	- func: SetTooltip(bool)
	- desc: sets the object's tooltip text
--]]---------------------------------------------------------
function Base:SetTooltip(text)
	self.tooltip = text
	return self
end

function Base:GetTooltip()
	return self.tooltip
end
--[[---------------------------------------------------------
	- func: SetVisible(bool)
	- desc: sets the object's visibility
--]]---------------------------------------------------------
function Base:SetVisible(bool)
	local children = self.children
	local internals = self.internals
	self.visible = bool

	if loveframes.inputobject == self then
		loveframes.inputobject = nil
	end
	if loveframes.hoverobject == self then
		loveframes.hoverobject = nil
	end
	if loveframes.draggingobject == self then
		loveframes.draggingobject = nil
	end
	if loveframes.hoverobject == self then
		loveframes.hoverobject = nil
	end
	if loveframes.downobject == self then
		loveframes.downobject = nil
	end

	if children then
		for k, v in pairs(children) do
			v:SetVisible(bool)
		end
	end
	if internals then
		for k, v in pairs(internals) do
			v:SetVisible(bool)
		end
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetVisible()
	- desc: gets the object's visibility
--]]---------------------------------------------------------
function Base:GetVisible()
	return self.visible
end

Base.IsVisible = Base.GetVisible
--[[---------------------------------------------------------
	- func: IsDragging()
	- desc: gets the object's dragging status
--]]---------------------------------------------------------
function Base:IsDragging(x, y, w, h)
	local drag = ( loveframes.draggingobject == self )
	if drag and (x and y and w and h) then
		local ax, ay = loveframes.GetAnchors()
		return (ax >= x and ay >= y and ax <= w and ay <= h)
	end
	return drag
end

function Base:Drag(mx, my)
	local parent = self.parent
	local base = loveframes.base
	mx = mx or love.mouse.getX()
	my = my or love.mouse.getY()
	if parent == base then
		self.x = mx - loveframes.anchor_x
		self.y = my - loveframes.anchor_y
	else
		self.staticx = mx - parent.x - loveframes.anchor_x
		self.staticy = my - parent.y - loveframes.anchor_y
	end
end

function Base:DragX()
	local parent = self.parent
	local base = loveframes.base

	local x, y = love.mouse.getX()
	if parent == base then
		self.x = x - loveframes.anchor_x
	else
		self.staticx = x - parent.x - loveframes.anchor_x
	end
end

function Base:DragY()
	local parent = self.parent
	local base = loveframes.base

	local x, y = love.mouse.getPosition()
	if parent == base then
		self.y = y - loveframes.anchor_y
	else
		self.staticy = y - parent.y - loveframes.anchor_y
	end
end

---@param mx number
---@param my number
---@return "top"|"bottom"|"left"|"right"|"top_left"|"top_right"|"bottom_left"|"bottom_right"|nil
function Base:GetResizeZone(mx, my)
	mx = mx or love.mouse.getX()
	my = my or love.mouse.getY()

	local margin = self.resizemargin or 6
	local x, y, w, h = self.x, self.y, self.width, self.height
    local left   = mx >= x and mx <= x + margin
    local right  = mx >= (x + w) - margin and mx <= (x + w)-1
    local top    = my >= y and my <= y + margin
    local bottom = my >= (y + h) - margin and my <= (y + h)-1

	if top and left then
		return "top_left"
	elseif top and right then
		return "top_right"
	elseif bottom and left then
		return "bottom_left"
	elseif bottom and right then
		return "bottom_right"
	elseif top then
		return "top"
	elseif bottom then
		return "bottom"
	elseif left then
		return "left"
	elseif right then
		return "right"
	end
    return nil
end

function Base:IsResizing(margin)
	margin = margin or 6
	local drag = ( loveframes.draggingobject == self )
	local ax, ay, x, y, width, height = loveframes.GetAnchors()
    local left   = (ax >= 0 and ax <= margin)
    local right  = (ax >= width - margin and ax <= width)
    local top    = (ay >= 0 and ay <= margin)
    local bottom = (ay >= height - margin and ay <= height)
	return drag and (left or right or top or bottom)
end

function Base:Resize(mx, my)
	mx = mx or love.mouse.getX()
	my = my or love.mouse.getY()

	local ax, ay, x, y, width, height = loveframes.GetAnchors()
	local margin = self.resizemargin or 6
    local left   = ax >= 0 and ax <= margin
    local right  = ax >= width - margin and ax <= width
    local top    = ay >= 0 and ay <= margin
    local bottom = ay >= height - margin and ay <= height
    local min_width = self.minwidth or 100
	local max_width = self.maxwidth or 400
	local min_height = self.minheight or 100
	local max_height = self.maxheight or 400
	local new_width, new_height = width, height
	if bottom then new_height = height - y + (my-ay) end
	if right then new_width = width - x + (mx-ax) end
	if left then new_width = width + x - (mx-ax) end
	if top then new_height = height + y - (my-ay) end

	if new_width >= min_width and new_width <= max_width then
		if left then
			self.x = x - (new_width - width)
		end
		self.width = new_width
	end
	if new_height >= min_height and new_height <= max_height then
		if top then
			self.y = y - (new_height - height)
		end
		self.height = new_height
	end
end

--[[---------------------------------------------------------
	- func: SetParent(parent)
	- desc: sets the object's parent
--]]---------------------------------------------------------
function Base:SetParent(parent)
	if self.orphan then
		-- Dont add frames inside objects
		self.parent = loveframes.base
		self:SetState( loveframes.base.state )
		table.insert( loveframes.base.children, self )
		return self
	end

	if parent.container then
		-- Call the override function if available
		if parent.AddItemIntoContainer then
			parent:AddItemIntoContainer(self)
			return self
		end
	end

	if parent.children then

		self:Remove()
		self.parent = parent
		self:SetState(parent.state)
		table.insert(parent.children, self)

	end

	return self
end

--[[---------------------------------------------------------
	- func: GetParent()
	- desc: gets the object's parent
--]]---------------------------------------------------------
function Base:GetParent()
	local parent = self.parent
	return parent
end
--[[---------------------------------------------------------
	- func: Remove()
	- desc: removes the object
--]]---------------------------------------------------------
function Base:Remove()
	local pinternals = self.parent.internals
	local pchildren = self.parent.children
	if pinternals then
		for k, v in pairs(pinternals) do
			if v == self then
				table.remove(pinternals, k)
			end
		end
	end
	if pchildren then
		for k, v in pairs(pchildren) do
			if v == self then
				table.remove(pchildren, k)
			end
		end
	end
	return self
end

--[[---------------------------------------------------------
	- func: RemoveChildren()
	- desc: removes the object's children
--]]---------------------------------------------------------
function Base:RemoveChildren(...)
	local args = {...}
	if #args == 0 then
		args = self.children
	end
	for index, child in pairs(args) do
		child:Remove()
	end
end

--[[---------------------------------------------------------
	- func: SetClickBounds(x, y, width, height)
	- desc: sets a boundary box for the object's collision
			detection
--]]---------------------------------------------------------
function Base:SetClickBounds(x, y, width, height)
	local internals = self.internals
	local children = self.children
	self.clickbounds = self.clickbounds or {x = x, y = y, width = width, height = height}
	self.clickbounds.x = x
	self.clickbounds.y = y
	self.clickbounds.width = width
	self.clickbounds.height = height

	if internals then
		for k, v in pairs(internals) do
			v:SetClickBounds(x, y, width, height)
		end
	end
	if children then
		for k, v in pairs(children) do
			v:SetClickBounds(x, y, width, height)
		end
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetClickBounds()
	- desc: gets the boundary box for the object's collision
			detection
--]]---------------------------------------------------------
function Base:GetClickBounds()
	return self.clickbounds
end

--[[---------------------------------------------------------
	- func: RemoveClickBounds()
	- desc: removes the collision detection boundary for the 
			object 
--]]---------------------------------------------------------
function Base:RemoveClickBounds()
	local internals = self.internals
	local children = self.children
	self.clickbounds = nil
	if internals then
		for k, v in pairs(internals) do
			v:RemoveClickBounds()
		end
	end
	if children then
		for k, v in pairs(children) do
			v:RemoveClickBounds()
		end
	end
	return self
end

--[[---------------------------------------------------------
	- func: InClickBounds()
	- desc: checks if the mouse is inside the object's
			collision detection boundaries
--]]---------------------------------------------------------
function Base:InClickBounds()
	local x, y = love.mouse.getPosition()
	local bounds = self.clickbounds
	if bounds then
		local col = loveframes.BoundingBox(x, bounds.x, y, bounds.y, 1, bounds.width, 1, bounds.height)
		return col
	else
		return false
	end
	return self
end

function Base:InBounds()
	local x, y = love.mouse.getPosition()
	local col = loveframes.BoundingBox(
		x,
		self.x,
		y, self.y,
		1,
		self.width,
		1,
		self.height
	)

	return col
end

--[[---------------------------------------------------------
	- func: GetBaseParent(object, t)
	- desc: finds the object's base parent
--]]---------------------------------------------------------
function Base:GetBaseParent()
	local base = loveframes.base
	local parent = self.parent
	if parent == base then
		return self
	end
	if parent.parent == base then
		return parent
	else
		return parent:GetBaseParent()
	end
end

--[[---------------------------------------------------------
	- func: CheckHover()
	- desc: checks to see if the object should be in a
			hover state
--]]---------------------------------------------------------
function Base:CheckHover()
	local x 		= self.x
	local y 		= self.y
	local width 	= self.width
	local height 	= self.height
	local type 		= self.type
	local mx, my 	= love.mouse.getPosition()

	local selfcol 			= loveframes.BoundingBox(mx, x, my, y, 1, width, 1, height)
	local collisioncount 	= loveframes.collisioncount
	local hoverobject 		= loveframes.GetHoverObject()

	-- check if the mouse is colliding with the object
	if self:OnState() and self:IsVisible() then
		local collide = self.collide
		if selfcol and collide then
			loveframes.collisioncount = collisioncount + 1
			local clickbounds = self.clickbounds
			if clickbounds then
				local cx = clickbounds.x
				local cy = clickbounds.y
				local cwidth = clickbounds.width
				local cheight = clickbounds.height
				local clickcol = loveframes.BoundingBox(mx, cx, my, cy, 1, cwidth, 1, cheight)
				if clickcol then
					--table.insert(loveframes.collisions, self)
					loveframes.collisions = self
				end
			else
				loveframes.collisions = self
			end
		end
	end
	
	-- check if the object is being hovered
	if hoverobject == self and type ~= "base" then
		self.hover = true
		if self.parent and self.parent.container then
			self.parent.hover = true
		end
	else
		self.hover = false
	end


	local hover = self.hover
	local calledmousefunc = self.calledmousefunc
	-- check for mouse enter and exit events
	if hover then
		if not calledmousefunc then
			self.hovertime = love.timer.getTime()
			local on_mouse_enter = self.OnMouseEnter
			if on_mouse_enter then
				on_mouse_enter(self)
				self.calledmousefunc = true
			else
				self.calledmousefunc = true
			end
		end
	else
		if calledmousefunc then
			self.hovertime = 0
			local on_mouse_exit = self.OnMouseExit
			if on_mouse_exit then
				on_mouse_exit(self)
				self.calledmousefunc = false
			else
				self.calledmousefunc = false
			end
		end
	end
end

--[[---------------------------------------------------------
	- func: GetHover()
	- desc: return if the object is in a hover state or not
--]]---------------------------------------------------------
function Base:GetHover()
	return self.hover
end

function Base:GetHoverTime()
	return love.timer.getTime() - self.hovertime
end

--[[---------------------------------------------------------
	- func: GetChildren()
	- desc: returns the object's children
--]]---------------------------------------------------------
function Base:GetChildren()
	local children = self.children
	if children then
		return children
	end
end

--[[---------------------------------------------------------
	- func: GetInternals()
	- desc: returns the object's internals
--]]---------------------------------------------------------
function Base:GetInternals()
	local internals = self.internals
	if internals then
		return internals
	end
end


--[[---------------------------------------------------------
	- func: IsTopList()
	- desc: returns true if the object is the top most list
			object or false if not
--]]---------------------------------------------------------
function Base:IsTopList()
	local cols = loveframes.GetCollisions()
	local children = self:GetChildren()
	local order = self.draworder
	local top = true
	local found = false
	local function IsChild(object)
		local parents = object:GetParents()
		for k, v in pairs(parents) do
			if v == self then
				return true
			end
		end
		return false
	end
	for k, v in pairs(cols) do
		if v == self then
			found = true
		else
			if v.draworder > order then
				if IsChild(v) ~= true then
					top = false
					break
				end
			end
		end
	end
	if found == false then
		top = false
	end
	return top
end

--[[---------------------------------------------------------
	- func: IsTopChild()
	- desc: returns true if the object is the top most child
			in its parent's children table or false if not
--]]---------------------------------------------------------
function Base:IsTopChild()
	local children = self.parent.children
	local num = #children
	if children[num] == self then
		return true
	else
		return false
	end
end

--[[---------------------------------------------------------
	- func: MoveToTop()
	- desc: moves the object to the top of its parent's
			children table
--]]---------------------------------------------------------
function Base:MoveToTop()
	if self == loveframes.base then
		return self
	end

	local pchildren = self.parent.children
	local pinternals = self.parent.internals
	local internal = false
	if pinternals then
		for k, v in pairs(pinternals) do
			if v == self then
				internal = true
			end
		end
	end
	self:Remove()
	if internal then
		if pinternals then
			table.insert(pinternals, self)
		end
	else
		if pchildren then
			table.insert(pchildren, self)
		end
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetDrawFunc()
	- desc: sets the objects skin based draw function
--]]---------------------------------------------------------
function Base:SetDrawFunc()
	local skins = loveframes.skins
	local activeskin  = skins[loveframes.config["ACTIVESKIN"]]
	--local defaultskin = skins[loveframes.config["DEFAULTSKIN"]]
	local funcname = self.type
	self.drawfunc = activeskin[funcname] -- or defaultskin[funcname]
	funcname = self.type .. "_over"
	self.drawoverfunc = activeskin[funcname] -- or defaultskin[funcname]
end

--[[---------------------------------------------------------
	- func: SetSkin(name)
	- desc: sets the object's skin
--]]---------------------------------------------------------
function Base:SetSkin(name)
	local children = self.children
	local internals = self.internals
	self.skin = name
	local selfskin = loveframes.skins[name]
	local funcname = self.type
	self.drawfunc = selfskin[funcname]
	self.drawoverfunc = selfskin[funcname.."_over"]
	if children then
		for k, v in pairs(children) do
			v:SetSkin(name)
		end
	end
	if internals then
		for k, v in pairs(internals) do
			v:SetSkin(name)
		end
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetSkin()
	- desc: gets the object's skin
--]]---------------------------------------------------------
function Base:GetSkin()
	local skins = loveframes.skins
	local skinindex = loveframes.config["ACTIVESKIN"]
	local defaultskin = loveframes.config["DEFAULTSKIN"]
	local selfskin = self.skin
	local skin = skins[selfskin] or skins[skinindex]
	return skin
end

--[[---------------------------------------------------------
	- func: GetSkinName()
	- desc: gets the name of the object's skin
--]]---------------------------------------------------------
function Base:GetSkinName()
	return self.skin
end

--[[---------------------------------------------------------
	- func: SetAlwaysUpdate(bool)
	- desc: sets the object's skin
--]]---------------------------------------------------------
function Base:SetAlwaysUpdate(bool)
	self.alwaysupdate = bool
	return self
end

--[[---------------------------------------------------------
	- func: GetAlwaysUpdate()
	- desc: gets whether or not the object will always update
--]]---------------------------------------------------------
function Base:GetAlwaysUpdate()
	return self.alwaysupdate
end

--[[---------------------------------------------------------
	- func: SetRetainSize(bool)
	- desc: sets whether or not the object should retain its
			size when another object tries to resize it
--]]---------------------------------------------------------
function Base:SetRetainSize(bool)
	self.retainsize = bool
	return self
end

--[[---------------------------------------------------------
	- func: GetRetainSize()
	- desc: gets whether or not the object should retain its
			size when another object tries to resize it
--]]---------------------------------------------------------
function Base:GetRetainSize()
	return self.retainsize
end

--[[---------------------------------------------------------
	- func: IsActive()
	- desc: gets whether or not the object is active within
			its parent's child table
--]]---------------------------------------------------------
function Base:IsActive()
	local parent = self.parent
	local pchildren = parent.children
	local valid = false
	for k, v in pairs(pchildren) do
		if v == self then
			valid = true
		end
	end
	return valid
end

--[[---------------------------------------------------------
	- func: GetParents()
	- desc: returns a table of the object's parents and its
			sub-parents
--]]---------------------------------------------------------
function Base:GetParents()
	local function GetParents(object, t)
		t = t or {}
		local type = object.type
		local parent = object.parent
		if type ~= "base" then
			table.insert(t, parent)
			GetParents(parent, t)
		end
		return t
	end
	local parents = GetParents(self)
	return parents
end

--[[---------------------------------------------------------
	- func: IsTopInternal()
	- desc: returns true if the object is the top most 
			internal in its parent's internals table or 
			false if not
--]]---------------------------------------------------------
function Base:IsTopInternal()
	local parent = self.parent
	local internals = parent.internals
	local topitem = internals[#internals]
	if topitem ~= self then
		return false
	else
		return true
	end
end

--[[---------------------------------------------------------
	- func: IsInternal()
	- desc: returns true if the object is internal or 
			false if not
--]]---------------------------------------------------------
function Base:IsInternal()
	return self.internal
end

--[[---------------------------------------------------------
	- func: GetType()
	- desc: gets the type of the object
--]]---------------------------------------------------------
function Base:GetType()
	return self.type
end

--[[---------------------------------------------------------
	- func: SetDrawOrder()
	- desc: sets the object's draw order
--]]---------------------------------------------------------
function Base:SetDrawOrder()
	loveframes.drawcount = loveframes.drawcount + 1
	self.draworder = loveframes.drawcount
	return self
end

--[[---------------------------------------------------------
	- func: GetDrawOrder()
	- desc: sets the object's draw order
--]]---------------------------------------------------------
function Base:GetDrawOrder()
	return self.draworder
end

--[[---------------------------------------------------------
	- func: SetCursor(name, value)
	- desc: sets the system cursor used when hovering this object
--]]---------------------------------------------------------
function Base:SetCursor(cursor)
	self.cursor = cursor
	return self
end

--[[---------------------------------------------------------
	- func: GetProperty(name)
	- desc: gets the system cursor used when hovering this object
--]]---------------------------------------------------------
function Base:GetCursor(name)
	return self.cursor
end

--[[---------------------------------------------------------
	- func: SetProperty(name, value)
	- desc: sets a property on the object
--]]---------------------------------------------------------
function Base:SetProperty(name, value)
	self[name] = value
	return self
end

--[[---------------------------------------------------------
	- func: GetProperty(name)
	- desc: gets the value of an object's property
--]]---------------------------------------------------------
function Base:GetProperty(name)
	return self[name]
end

--[[---------------------------------------------------------
	- func: IsInList()
	- desc: checks to see if an object is in a list
--]]---------------------------------------------------------
function Base:IsInList()
	local parents = self:GetParents()
	for k, v in pairs(parents) do
		if v.type == "list" then
			return true, v
		end
	end
	return false, false
end

--[[---------------------------------------------------------
	- func: SetState(name)
	- desc: sets the object's state
--]]---------------------------------------------------------
function Base:SetState(name)
	name = name or "none"
	local children = self.children
	local internals = self.internals
	self.state = name
	if children then
		for k, v in pairs(children) do
			v:SetState(name)
		end
	end
	if internals then
		for k, v in pairs(internals) do
			v:SetState(name)
		end
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetState()
	- desc: gets the object's state
--]]---------------------------------------------------------
function Base:GetState()
	return self.state
end
--[[---------------------------------------------------------
	- func: SetCollidable/GetCollidable()
	- desc: gets/sets the object's collidable status
--]]---------------------------------------------------------
function Base:SetCollidable(bool)
	self.collide = bool
	return self
end

function Base:GetCollidable(bool)
	return self.collide
end

--[[---------------------------------------------------------
	- func: OnState()
	- desc: compares the object's self state with the global state
--]]---------------------------------------------------------
function Base:OnState()
	local state = loveframes.state
	local selfstate = self.state
	if selfstate == "*" then return true end
	if state ~= selfstate then
		return false
	end
	return true
end

--[[---------------------------------------------------------
	- func: isUpdating
	- desc: compares the object's visibility
--]]---------------------------------------------------------
function Base:isUpdating()
	return self.visible or self.alwaysupdate
end

function Base:isRoot()
	return self == loveframes.base
end

---------- module end ----------
end