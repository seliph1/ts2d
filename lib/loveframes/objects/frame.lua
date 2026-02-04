--[[------------------------------------------------
-- Love Frames - A GUI library for LOVE --
-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
---------- module start ----------

-- frame object
local Frame = loveframes.NewObject("frame", "loveframes_object_frame", true)

--[[---------------------------------------------------------
- func: initialize()
- desc: initializes the object
--]] ---------------------------------------------------------
function Frame:initialize()
	self.type = "frame"
	self.name = "Frame"
	self.container = true
	self.width = 300
	self.height = 150
	self.clickx = 0
	self.clicky = 0
	self.orphan = true
	self.internal = false
	self.screenlocked = false
	self.parentlocked = false
	self.modal = false
	self.modalbackground = false
	self.showclose = true
	self.candrag = true
	self.canresize = false
	self.resizemargin = 6
	self.minwidth = 100
	self.minheight = 30
	self.maxwidth = 500
	self.maxheight = 500
	self.alwaysontop = false
	self.internals = {}
	self.children = {}
	self.icon = nil
	self.toprequest = false
	self.OnClose = nil
	self.OnResize = nil

	-- create the close button for the frame
	local close = loveframes.objects["closebutton"]:new()
	close.parent = self
	close.OnClick = function(x, y, object)
		local onclose = self.OnClose
		if onclose then
			onclose(self)
		end
		object.parent:Remove()
	end
	table.insert(self.internals, close)
	self:SetDrawFunc()
end

--[[---------------------------------------------------------
- func: update(deltatime)
- desc: updates the element
--]] ---------------------------------------------------------
function Frame:update(dt)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local mx, my = love.mouse.getPosition()
	local screenlocked = self.screenlocked
	local parentlocked = self.parentlocked
	local modal = self.modal
	local base = loveframes.base
	local basechildren = base.children
	local children = self.children
	local internals = self.internals
	local parent = self.parent
	local update = self.Update
	self:CheckHover()

	--[[
	if self.canresize then
		local zone = self.resizeanchor
		if not self.resizing then
			zone = self:GetResizeZone()
		end

		if zone == "top" or zone == "bottom" then
			self.cursor = loveframes.cursors.sizens
		elseif zone == "left" or zone == "right" then
			self.cursor = loveframes.cursors.sizewe
		elseif zone == "bottom_right" or zone == "top_left" then
			self.cursor = loveframes.cursors.sizenwse
		elseif zone == "top_right" or zone == "bottom_left" then
			self.cursor = loveframes.cursors.sizenesw
		else
			self.cursor = nil
		end
	end]]

	-- Resize check
	if self.canresize and self:IsResizing() then
		self:Resize(mx, my)
	end

	-- dragging check
	if self.candrag then
		local padding = self.resizemargin + 1
		local dragging
		if self.canresize then
			dragging = self:IsDragging(padding, padding, self.width - padding, 20)
		else
			dragging = self:IsDragging(0, 0, self.width, 20)
		end
		if dragging then
			self:Drag(mx, my)
		end
	end

	-- if screenlocked then keep within screen
	if screenlocked then
		local width = self.width
		local height = self.height
		local screenwidth = love.graphics.getWidth()
		local screenheight = love.graphics.getHeight()
		local x = self.x
		local y = self.y
		if x < 0 then self.x = 0 end
		if x + width > screenwidth then
			self.x = screenwidth - width
		end
		if y < 0 then self.y = 0 end
		if y + height > screenheight then
			self.y = screenheight - height
		end
	end

	-- keep the frame within its parent's boundaries if parentlocked
	if parentlocked then
		local width = self.width
		local height = self.height
		local parentwidth = self.parent.width
		local parentheight = self.parent.height
		local staticx = self.staticx
		local staticy = self.staticy
		if staticx < 0 then
			self.staticx = 0
		end
		if staticx + width > parentwidth then
			self.staticx = parentwidth - width
		end
		if staticy < 0 then
			self.staticy = 0
		end
		if staticy + height > parentheight then
			self.staticy = parentheight - height
		end
	end
	if parent == base and self.alwaysontop and not self:IsTopChild() then
		self:MakeTop()
	end
	if modal then
		local tip = false
		local key = 0
		for k, v in pairs(basechildren) do
			if v.type == "tooltip" and v.show then
				tip = v
				key = k
			end
		end
		local modalbackground = self.modalbackground
		if modalbackground then
			if tip then
				self:Remove()
				modalbackground:Remove()
				table.insert(basechildren, key - 2, modalbackground)
				table.insert(basechildren, key - 1, self)
			end
			if modalbackground.draworder > self.draworder then
				self:MakeTop()
			end
			if modalbackground.state ~= self.state then
				modalbackground:SetState(self.state)
			end
		end
	end
	if parent ~= base then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end
	for k, v in pairs(internals) do
		v:update(dt)
	end
	for k, v in pairs(children) do
		v:update(dt)
	end
	if update then
		update(self, dt)
	end

	-- Move to top if requested
	if self.toprequest then
		self.toprequest = false

		-- make this the top object
		for k, v in pairs(basechildren) do
			if v == self then
				table.remove(basechildren, k)
				table.insert(basechildren, self)
				break
			end
		end
	end

end

--[[---------------------------------------------------------
- func: mousepressed(x, y, button)
- desc: called when the player presses a mouse button
--]] ---------------------------------------------------------
function Frame:mousepressed(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local internals = self.internals
	local children = self.children

	if self.hover and button == 1 then
		self:MakeTop()
	end

	for k, v in pairs(children) do
		v:mousepressed(x, y, button)
	end
	for k, v in pairs(internals) do
		v:mousepressed(x, y, button)
	end
end

--[[---------------------------------------------------------
- func: mousereleased(x, y, button)
- desc: called when the player releases a mouse button
--]] ---------------------------------------------------------
function Frame:mousereleased(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local children = self.children
	local internals = self.internals

	self.cursor = nil

	for k, v in pairs(internals) do
		v:mousereleased(x, y, button)
	end
	for k, v in pairs(children) do
		v:mousereleased(x, y, button)
	end
end

--[[---------------------------------------------------------
- func: SetName(name)
- desc: sets the object's name
--]] ---------------------------------------------------------
function Frame:SetName(name)
	self.name = name
	return self
end

--[[---------------------------------------------------------
- func: GetName()
- desc: gets the object's name
--]] ---------------------------------------------------------
function Frame:GetName()
	return self.name
end

--[[---------------------------------------------------------
- func: SetDraggable(true/false)
- desc: sets whether the object can be dragged or not
--]] ---------------------------------------------------------
function Frame:SetDraggable(bool)
	self.candrag = bool
	return self
end

--[[---------------------------------------------------------
- func: GetDraggable()
- desc: gets whether the object can be dragged ot not
--]] ---------------------------------------------------------
function Frame:GetDraggable()
	return self.candrag
end

--[[---------------------------------------------------------
- func: SetScreenLocked(bool)
- desc: sets whether the object can be moved passed the
		boundaries of the window or not
--]] ---------------------------------------------------------
function Frame:SetScreenLocked(bool)
	self.screenlocked = bool
	return self
end

--[[---------------------------------------------------------
- func: GetScreenLocked()
- desc: gets whether the object can be moved passed the
		boundaries of window or not
--]] ---------------------------------------------------------
function Frame:GetScreenLocked()
	return self.screenlocked
end

--[[---------------------------------------------------------
- func: ShowCloseButton(bool)
- desc: sets whether the object's close button should
		be drawn
--]] ---------------------------------------------------------
function Frame:ShowCloseButton(bool)
	local close = self.internals[1]
	close.visible = bool
	self.showclose = bool
	return self
end

--[[---------------------------------------------------------
- func: SetCloseAction(bool)
- desc: set what the close button should do to this window
--]] ---------------------------------------------------------
---@param f "close"|"hide"|fun(x:number,y:number,object:table)
function Frame:SetCloseAction(f)
	local close = self.internals[1]
	if type(f) == "string" then
		if f == "close" then
			close.OnClick = function(x, y, object)
				object.parent:Remove()
			end
		elseif f == "hide" then
			close.OnClick = function(x, y, object)
				object.parent:SetVisible(false)
			end
		end
	elseif type(f) == "function" then
		close.OnClick = f
		return self
	end
	return self
end

--[[---------------------------------------------------------
- func: MakeTop()
- desc: makes the object the top object in the drawing
		order
--]] ---------------------------------------------------------
function Frame:MakeTop()
	local base = loveframes.base
	local basechildren = base.children
	local numbasechildren = #basechildren
	-- check to see if the object's parent is not the base object
	if self.parent ~= base then
		local baseparent = self:GetBaseParent()
		if baseparent.type == "frame" then
			baseparent:MakeTop()
		end
		return self
	end
	-- check to see if the object is the only child of the base object
	if numbasechildren == 1 then
		return self
	end
	-- check to see if the object is already at the top
	if basechildren[numbasechildren] == self then
		return self
	end

	self.toprequest = true
	return self
end

--[[---------------------------------------------------------
- func: SetModal(bool)
- desc: sets whether or not the object is in a modal
		state
--]] ---------------------------------------------------------
function Frame:SetModal(bool)
	local modalobject = loveframes.modalobject
	local mbackground = self.modalbackground
	local parent = self.parent
	local base = loveframes.base
	if parent ~= base then
		return
	end
	self.modal = bool
	if bool then
		if modalobject then
			modalobject:SetModal(false)
		end
		loveframes.modalobject = self
		if not mbackground then
			self.modalbackground = loveframes.objects["modalbackground"]:new(self)
			self.modal = true
		end
	else
		if modalobject == self then
			loveframes.modalobject = false
			if mbackground then
				mbackground:Remove()
				self.modalbackground = false
				self.modal = false
			end
		end
	end
	return self
end

--[[---------------------------------------------------------
- func: GetModal()
- desc: gets whether or not the object is in a modal
		state
--]] ---------------------------------------------------------
function Frame:GetModal()
	return self.modal
end

--[[---------------------------------------------------------
- func: SetVisible(bool)
- desc: set's whether the object is visible or not
--]] ---------------------------------------------------------
function Frame:SetVisible(bool)
	local children = self.children
	local internals = self.internals
	local closebutton = internals[1]
	self.visible = bool
	for k, v in pairs(children) do
		v:SetVisible(bool)
	end
	if self.showclose then
		closebutton.visible = bool
	end
	return self
end

--[[---------------------------------------------------------
- func: ToggleVisibility(bool)
- desc: set's whether the object is visible or not
--]] ---------------------------------------------------------
function Frame:ToggleVisibility()
	local toggle = not self.visible
	self:SetVisible(toggle)
end

--[[---------------------------------------------------------
- func: SetParentLocked(bool)
- desc: sets whether the object can be moved passed the
		boundaries of its parent or not
--]] ---------------------------------------------------------
function Frame:SetParentLocked(bool)
	self.parentlocked = bool
	return self
end

--[[---------------------------------------------------------
- func: GetParentLocked(bool)
- desc: gets whether the object can be moved passed the
		boundaries of its parent or not
--]] ---------------------------------------------------------
function Frame:GetParentLocked()
	return self.parentlocked
end

--[[---------------------------------------------------------
- func: SetIcon(icon)
- desc: sets the object's icon
--]] ---------------------------------------------------------
function Frame:SetIcon(icon)
	if type(icon) == "string" then
		self.icon = love.graphics.newImage(icon)
		self.icon:setFilter("nearest", "nearest")
	else
		self.icon = icon
	end
	return self
end

--[[---------------------------------------------------------
- func: GetIcon()
- desc: gets the object's icon
--]] ---------------------------------------------------------
function Frame:GetIcon()
	local icon = self.icon
	if icon then
		return icon
	end
	return false
end

--[[---------------------------------------------------------
- func: SetDockable(dockable)
- desc: sets whether or not the object can dock onto
		another object of its type or be docked
		by another object of its type
--]] ---------------------------------------------------------
function Frame:SetDockable(dockable)
	self.dockable = dockable
	return self
end

--[[---------------------------------------------------------
- func: GetDockable()
- desc: gets whether or not the object can dock onto
		another object of its type or be docked
		by another object of its type
--]] ---------------------------------------------------------
function Frame:GetDockable()
	return self.dockable
end

--[[---------------------------------------------------------
- func: SetDockZoneSize(size)
- desc: sets the size of the object's docking zone
--]] ---------------------------------------------------------
function Frame:SetDockZoneSize(size)
	self.dockzonesize = size
	return self
end

--[[---------------------------------------------------------
- func: GetDockZoneSize(size)
- desc: gets the size of the object's docking zone
--]] ---------------------------------------------------------
function Frame:GetDockZoneSize()
	return self.dockzonesize
end

--[[---------------------------------------------------------
- func: SetResizable(bool)
- desc: sets whether or not the object can be resized
--]] ---------------------------------------------------------
function Frame:SetResizable(bool)
	self.canresize = bool
	return self
end

--[[---------------------------------------------------------
- func: GetResizable()
- desc: gets whether or not the object can be resized
--]] ---------------------------------------------------------
function Frame:GetResizable()
	return self.canresize
end

--[[---------------------------------------------------------
- func: SetMinWidth(width)
- desc: sets the object's minimum width
--]] ---------------------------------------------------------
function Frame:SetMinWidth(width)
	self.minwidth = width
	return self
end

--[[---------------------------------------------------------
- func: GetMinWidth()
- desc: gets the object's minimum width
--]] ---------------------------------------------------------
function Frame:GetMinWidth()
	return self.minwidth
end

--[[---------------------------------------------------------
- func: SetMaxWidth(width)
- desc: sets the object's maximum width
--]] ---------------------------------------------------------
function Frame:SetMaxWidth(width)
	self.maxwidth = width
	return self
end

--[[---------------------------------------------------------
- func: GetMaxWidth()
- desc: gets the object's maximum width
--]] ---------------------------------------------------------
function Frame:GetMaxWidth()
	return self.maxwidth
end

--[[---------------------------------------------------------
- func: SetMinHeight(height)
- desc: sets the object's minimum height
--]] ---------------------------------------------------------
function Frame:SetMinHeight(height)
	self.minheight = height
	return self
end

--[[---------------------------------------------------------
- func: GetMinHeight()
- desc: gets the object's minimum height
--]] ---------------------------------------------------------
function Frame:GetMinHeight()
	return self.minheight
end

--[[---------------------------------------------------------
- func: SetMaxHeight(height)
- desc: sets the object's maximum height
--]] ---------------------------------------------------------
function Frame:SetMaxHeight(height)
	self.maxheight = height
	return self
end

--[[---------------------------------------------------------
- func: GetMaxHeight()
- desc: gets the object's maximum height
--]] ---------------------------------------------------------
function Frame:GetMaxHeight()
	return self.maxheight
end

--[[---------------------------------------------------------
- func: SetMinSize(width, height)
- desc: sets the object's minimum size
--]] ---------------------------------------------------------
function Frame:SetMinSize(width, height)
	self.minwidth = width
	self.minheight = height
	return self
end

--[[---------------------------------------------------------
- func: GetMinSize()
- desc: gets the object's minimum size
--]] ---------------------------------------------------------
function Frame:GetMinSize()
	return self.minwidth, self.maxwidth
end

--[[---------------------------------------------------------
- func: SetMaxSize(width, height)
- desc: sets the object's maximum size
--]] ---------------------------------------------------------
function Frame:SetMaxSize(width, height)
	self.maxwidth = width
	self.maxheight = height
	return self
end

--[[---------------------------------------------------------
- func: GetMaxSize()
- desc: gets the object's maximum size
--]] ---------------------------------------------------------
function Frame:GetMaxSize()
	return self.maxwidth, self.maxheight
end

--[[---------------------------------------------------------
- func: SetAlwaysOnTop(bool)
- desc: sets whether or not a frame should always be
		drawn on top of other objects
--]] ---------------------------------------------------------
function Frame:SetAlwaysOnTop(bool)
	self.alwaysontop = bool
	return self
end

--[[---------------------------------------------------------
- func: GetAlwaysOnTop()
- desc: gets whether or not a frame should always be
		drawn on top of other objects
--]] ---------------------------------------------------------
function Frame:GetAlwaysOnTop()
	return self.alwaysontop
end

---------- module end ----------
end
