--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- list object
local newobject = loveframes.NewObject("scrollpane", "loveframes_object_scrollpane", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	self.type = "scrollpane"
	self.display = "vertical"
	self.container = true
	self.width = 300
	self.height = 150
	self.clickx = 0
	self.clicky = 0
	self.padding = 0
	self.spacing = 0
	self.offsety = 0
	self.offsetx = 0
	self.last_offsetx = -1
	self.last_offsety = -1
	self.extrawidth = 0
	self.extraheight = 0
	self.buttonscrollamount = 0.10
	self.mousewheelscrollamount = 10
	self.internal = false
	self.hbar = false
	self.vbar = false
	self.autoscroll = false
	self.horizontalstacking = false
	self.dtscrolling = false
	self.internals = {}
	self.children = {}
	self.OnScroll = nil
	self.itemcache = {}
	self.itemlength = 0
	self.itemhash = loveframes.bump.newWorld(64)
	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function newobject:update(dt)
	if not self:OnState() then return end
	if not self:IsVisible() then return end
	local x = self.x
	local y = self.y
	local width = self.width
	local height = self.height
	local offsetx = self.offsetx
	local offsety = self.offsety
	local parent = self.parent
	local internals = self.internals
	local base = loveframes.base
	local update = self.Update
	-- move to parent if there is a parent
	if parent ~= base and parent.type ~= "list" then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end
	-- Cache the last scrolled position
	local scrolled = false
	if offsetx ~= self.last_offsetx or offsety ~= self.last_offsety then
		scrolled = true
	end
	self.last_offsetx = offsetx
	self.last_offsety = offsety

	self:CheckHover()
	if scrolled then
		self.itemcache, self.itemlength = self.itemhash:queryRect(offsetx, offsety, self.width, self.height)
	end
	for i = 1, self.itemlength do
		local child = self.itemcache[i]
		child:update(dt)
		child:SetClickBounds(x, y, width, height)
		child.x = child.x - offsetx
		child.y = child.y - offsety
	end

	for _, internal in pairs(internals) do
		internal:update(dt)
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
	if not self:IsVisible() then return end
	local x = self.x
	local y = self.y
	local width = self.width
	local height = self.height
	local drawfunc = self.Draw or self.drawfunc
	local drawoverfunc = self.DrawOver or self.drawoverfunc
	local internals = self.internals
	self:SetDrawOrder()
	if drawfunc then
		drawfunc(self)
	end
	local cut_x = self.vbar and -16 or 0
	local cut_y = self.hbar and -16 or 0
	love.graphics.setScissor(x, y, width + cut_x, height + cut_y)
	for i = 1, self.itemlength do
		local child = self.itemcache[i]
		child:draw()
	end
	love.graphics.setScissor()
	if drawoverfunc then
		drawoverfunc(self)
	end
	if internals then
		for k, v in ipairs(internals) do
			v:draw()
		end
	end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button)
	if not self:OnState() then return end
	if not self:IsVisible() then return end
	local hover = self.hover
	local children = self.children
	local internals = self.internals
	if hover and button == 1 then
		local baseparent = self:GetBaseParent()
		if baseparent and baseparent.type == "frame" then
			baseparent:MakeTop()
		end
	end
	for k, v in pairs(internals) do
		v:mousepressed(x, y, button)
	end
	for k, v in pairs(children) do
		v:mousepressed(x, y, button)
	end
end

--[[---------------------------------------------------------
	- func: wheelmoved(x, y)
	- desc: called when the player moves a mouse wheel
--]]---------------------------------------------------------
function newobject:wheelmoved(x, y)
	if not self:OnState() then return end
	if not self:IsVisible() then return end
	local children = self.children
	if children then
		for k, v in ipairs(children) do
			v:wheelmoved(x, y)
		end
	end
	local internals = self.internals
	if internals then
		for k, v in ipairs(internals) do
			v:wheelmoved(x, y)
		end
	end
end

--[[---------------------------------------------------------
	- func: AddItem(object)
	- desc: adds an item to the object
--]]---------------------------------------------------------
function newobject:AddItem(object)
	if object.type == "frame" then -- Dont 
		return
	end
	-- remove the item object from its current parent and make its new parent the list object
	object:Remove()
	object.parent = self
	object:SetState(self.state)

	-- Reposition the object relative to parent
	object.staticx = object.x
	object.staticy = object.y

	-- insert the item object into the list object's children table
	table.insert(self.children, object)

	-- Insert item into hash table
	self.itemhash:add(object, object.staticx, object.staticy, object.width, object.height)

	-- Recalculate the size and redo the structure if needed
	self:RedoLayout()

	return self
end
newobject.AddItemIntoContainer = newobject.AddItem

function newobject:AddItemsFromTable(objects)
	for index, object in pairs(objects) do
		if object.type == "frame" then -- Dont 
			return
		end
		-- remove the item object from its current parent and make its new parent the list object
		object:Remove()
		object.parent = self
		object:SetState(self.state)

		-- Reposition the object relative to parent
		object.staticx = object.x
		object.staticy = object.y

		-- insert the item object into the list object's children table
		table.insert(self.children, object)

		-- Insert item into hash table
		self.itemhash:add(object, object.staticx, object.staticy, object.width, object.height)
	end
	self:RedoLayout()
	return self
end


--[[---------------------------------------------------------
	- func: RemoveItem(object or number)
	- desc: removes an item from the object
--]]---------------------------------------------------------
function newobject:RemoveItem(data)
	local dtype = type(data)
	if dtype == "number" then
		local children = self.children
		local item = children[data]
		if item then
			item:Remove()
		end
	else
		data:Remove()
	end
	-- Remove item into hash table
	if self.itemhash:hasItem(data) then
		self.itemhash:remove(data)
	end
	-- Update layout
	self:RedoLayout()
	return self
end

--[[---------------------------------------------------------
	- func: RedoLayout()
	- desc: redo the layout of the scrollpane
--]]---------------------------------------------------------
function newobject:RedoLayout()
	local height = self.height
	local width = self.width
	local vbar = self.vbar
	local hbar = self.hbar

	local min_x, min_y, max_x, max_y = 0,0,0,0
	for _, child in pairs(self.children) do
		if min_x > child.staticx then
			min_x = child.staticx
		end

		if min_y > child.staticy then
			min_y = child.staticy
		end

		if max_x < child.staticx + child.width then
			max_x = child.staticx + child.width
		end

		if max_y < child.staticy + child.height then
			max_y = child.staticy + child.height
		end

		-- Update the hash table
		self.itemhash:update(child, child.staticx, child.staticy, child.width, child.height)
	end
	self.itemwidth = max_x
	self.itemheight = max_y

	if self.itemheight > self.height then
		self.extraheight = self.itemheight - height
		--self.extraheight = self.extraheight + 16
		if not vbar then
			local verticalbar = loveframes.objects["scrollbody"]:new(self, "vertical")
			table.insert(self.internals, verticalbar)
			self.vbar = true
		end
	else
		if vbar then
			local verticalbar = self:GetVerticalScrollBody()
			if verticalbar then
				verticalbar:Remove()
			end
			self.vbar = false
			self.offsety = 0
		end
	end

	if self.itemwidth > self.width then
		self.extrawidth = self.itemwidth - width
		--self.extrawidth = self.extrawidth + 16
		if not hbar then
			local horizontalbar = loveframes.objects["scrollbody"]:new(self, "horizontal")
			table.insert(self.internals, horizontalbar)
			self.hbar = true
		end
	else
		if hbar then
			local horizontalbar = self:GetHorizontalScrollBody()
			if horizontalbar then
				horizontalbar:Remove()
			end
			self.hbar = false
			self.offsetx = 0
		end
	end
	--[[
	if hbar then
		self.extraheight = self.extraheight + 16
	end
	if vbar then
		self.extrawidth = self.extrawidth + 16
	end]]
end

--[[---------------------------------------------------------
	- func: Clear()
	- desc: removes all of the object's children
--]]---------------------------------------------------------
function newobject:Clear()
	local children = self.children
	self.children = {}
	for _, child in ipairs(children) do
		child:Remove()
		-- Remove item into hash table
		if self.itemhash:hasItem(child) then
			self.itemhash:remove(child)
		end
	end
	self:RedoLayout()
	return self
end

--[[---------------------------------------------------------
	- func: SetWidth(width, relative)
	- desc: sets the object's width
--]]---------------------------------------------------------
function newobject:SetWidth(width, relative)
	if relative then
		self.width = self.parent.width * width
	else
		self.width = width
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetHeight(height, relative)
	- desc: sets the object's height
--]]---------------------------------------------------------
function newobject:SetHeight(height, relative)
	if relative then
		self.height = self.parent.height * height
	else
		self.height = height
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetSize(width, height, r1, r2)
	- desc: sets the object's size
--]]---------------------------------------------------------
function newobject:SetSize(width, height, r1, r2)
	if r1 then
		self.width = self.parent.width * width
	else
		self.width = width
	end
	if r2 then
		self.height = self.parent.height * height
	else
		self.height = height
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetHorizontalScrollBody() GetVerticalScrollBody()
	- desc: gets the object's scroll body
--]]---------------------------------------------------------
function newobject:GetHorizontalScrollBody()
	for k, v in pairs(self.internals) do
		if v.bartype == "horizontal" then
			return v
		end
	end
	return false
end

function newobject:GetVerticalScrollBody()
	for k, v in pairs(self.internals) do
		if v.bartype == "vertical" then
			return v
		end
	end
	return false
end
--[[---------------------------------------------------------
	- func: GetScrollBar()
	- desc: gets the object's scroll bar
--]]---------------------------------------------------------
--[[
function newobject:GetScrollBar()
	local vbar = self.vbar
	local hbar = self.hbar
	local internals  = self.internals
	if vbar or hbar then
		local scrollbody = internals[1]
		local scrollarea = scrollbody.internals[1]
		local scrollbar = scrollarea.internals[1]
		return scrollbar
	else
		return false
	end
end
]]
--[[---------------------------------------------------------
	- func: SetAutoScroll(bool)
	- desc: sets whether or not the list's scrollbar should
			auto scroll to the bottom when a new object is
			added to the list
--]]---------------------------------------------------------
--[[
function newobject:SetAutoScroll(bool)
	local scrollbar = self:GetScrollBar()
	self.autoscroll = bool
	if scrollbar then
		scrollbar.autoscroll = bool
	end
	return self
end
]]
--[[---------------------------------------------------------
	- func: GetAutoScroll()
	- desc: gets whether or not the list's scrollbar should
			auto scroll to the bottom when a new object is
			added to the list
--]]---------------------------------------------------------
--[[
function newobject:GetAutoScroll()
	return self.autoscroll
end
]]
--[[---------------------------------------------------------
	- func: SetButtonScrollAmount(speed)
	- desc: sets the scroll amount of the object's scrollbar
			buttons
--]]---------------------------------------------------------
--[[function newobject:SetButtonScrollAmount(amount)
	self.buttonscrollamount = amount
	return self
end
]]
--[[---------------------------------------------------------
	- func: GetButtonScrollAmount()
	- desc: gets the scroll amount of the object's scrollbar
			buttons
--]]---------------------------------------------------------
--[[function newobject:GetButtonScrollAmount()
	return self.buttonscrollamount
end
]]
--[[---------------------------------------------------------
	- func: SetMouseWheelScrollAmount(amount)
	- desc: sets the scroll amount of the mouse wheel
--]]---------------------------------------------------------
function newobject:SetMouseWheelScrollAmount(amount)
	self.mousewheelscrollamount = amount
	return self
end

--[[---------------------------------------------------------
	- func: GetMouseWheelScrollAmount()
	- desc: gets the scroll amount of the mouse wheel
--]]---------------------------------------------------------
function newobject:GetMouseWheelScrollAmount()
	return self.mousewheelscrollamount
end

--[[---------------------------------------------------------
	- func: EnableHorizontalStacking(bool)
	- desc: enables or disables horizontal stacking
--]]---------------------------------------------------------
function newobject:EnableHorizontalStacking(bool)
	self.horizontalstacking = bool
	return self
end

--[[---------------------------------------------------------
	- func: GetHorizontalStacking()
	- desc: gets whether or not the object allows horizontal
			stacking
--]]---------------------------------------------------------
function newobject:GetHorizontalStacking()
	return self.horizontalstacking
end

--[[---------------------------------------------------------
	- func: SetDTScrolling(bool)
	- desc: sets whether or not the object should use delta
			time when scrolling
--]]---------------------------------------------------------
function newobject:SetDTScrolling(bool)
	self.dtscrolling = bool
	return self
end

--[[---------------------------------------------------------
	- func: GetDTScrolling()
	- desc: gets whether or not the object should use delta
			time when scrolling
--]]---------------------------------------------------------
function newobject:GetDTScrolling()
	return self.dtscrolling
end

---------- module end ----------
end
