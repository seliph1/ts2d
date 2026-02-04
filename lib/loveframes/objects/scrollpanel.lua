--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- list object
local ScrollPanel = loveframes.NewObject("scrollpanel", "loveframes_object_scrollpanel", true)
--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function ScrollPanel:initialize()
	self.type = "scrollpanel"
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
	self.buttonscrollamount = 1
	self.mousewheelscrollamount = 1
	self.internal = false
	self.hbar = false
	self.vbar = false
	self.autoscroll = false
	self.horizontalstacking = false
	self.dtscrolling = false
	self.internals = {}
	self.children = {}
	self.itemcache = {}
	self.itemlength = 0
	self.itemhash = loveframes.bump.newWorld(64)
	self.background = false
	self:SetDrawFunc()
	self.OnScroll = nil
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function ScrollPanel:update(dt)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

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
	if parent ~= base then
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
		self.itemcache, self.itemlength = self.itemhash:queryRect(
			self.last_offsetx,
			self.last_offsety,
			self.width,
			self.height
		)
	end

	for i = 1, self.itemlength do
		local child = self.itemcache[i]
		child:update(dt)
		child:SetClickBounds(x, y, width, height)
		child.x = math.floor( child.x - self.last_offsetx )
		child.y = math.floor( child.y - self.last_offsety )
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
function ScrollPanel:draw()
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local x = self.x
	local y = self.y
	local width = self.width
	local height = self.height
	local drawfunc = self.Draw or self.drawfunc
	local drawoverfunc = self.DrawOver or self.drawoverfunc
	local internals = self.internals
	self:SetDrawOrder()
	if drawfunc and self.background then
		drawfunc(self)
	end
	local cut_x = self.vbar and -16 or 0
	local cut_y = self.hbar and -16 or 0
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(x, y, width + cut_x, height + cut_y)
	for i = 1, self.itemlength do
		local child = self.itemcache[i]
		child:draw()
	end
	love.graphics.setScissor(ox, oy, ow, oh)
	if drawoverfunc then
		drawoverfunc(self)
	end
	if internals then
		for k, v in pairs(internals) do
			v:draw()
		end
	end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function ScrollPanel:mousepressed(x, y, button)
	ScrollPanel.super.mousepressed(self, x, y, button)

	if self.hover and button == 1 then
		local baseparent = self:GetBaseParent()
		if baseparent and baseparent.type == "frame" then
			baseparent:MakeTop()
		end
	end
end

--[[---------------------------------------------------------
	- func: AddItem(object)
	- desc: adds an item to the object
--]]---------------------------------------------------------
function ScrollPanel:AddItem(object)
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
ScrollPanel.AddItemIntoContainer = ScrollPanel.AddItem

function ScrollPanel:AddItemsFromTable(objects)
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
function ScrollPanel:RemoveItem(data)
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
	- desc: redo the layout of the scrollpanel
--]]---------------------------------------------------------
function ScrollPanel:RedoLayout()
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

	if self.hbar and self.vbar then
		-- If both are on together, they can cut visible area

		local horizontalbar = self:GetHorizontalScrollBody()
		local verticalbar = self:GetVerticalScrollBody()

		self.extrawidth = self.extrawidth + verticalbar.width
		self.extraheight = self.extraheight + horizontalbar.height
	end

	-- Do one cycle
	self.itemcache, self.itemlength = self.itemhash:queryRect(
		self.last_offsetx,
		self.last_offsety,
		self.width,
		self.height
	)
end

--[[---------------------------------------------------------
	- func: Clear()
	- desc: removes all of the object's children
--]]---------------------------------------------------------
function ScrollPanel:Clear()
	for index ,child in pairs(self.children) do
		--child:Remove()
	end
	self.itemhash:clear()
	self.children = {}
	self.itemcache = {}
	self.itemlength = 0

	self:RedoLayout()
	return self
end


--[[---------------------------------------------------------
	- func: GetHorizontalScrollBody() GetVerticalScrollBody()
	- desc: gets the object's scroll body
--]]---------------------------------------------------------
function ScrollPanel:GetHorizontalScrollBody()
	for k, v in pairs(self.internals) do
		if v.bartype == "horizontal" then
			return v
		end
	end
	--return false
end

function ScrollPanel:GetVerticalScrollBody()
	for k, v in pairs(self.internals) do
		if v.bartype == "vertical" then
			return v
		end
	end
	--return false
end

--[[---------------------------------------------------------
	- func: ShowBackground()
	- desc: set the background visibility
--]]---------------------------------------------------------
function ScrollPanel:ShowBackground(bool)
	self.background = bool
	return self
end
ScrollPanel.SetBackground = ScrollPanel.ShowBackground
--[[---------------------------------------------------------
	- func: GetScrollBar()
	- desc: gets the object's scroll bar
--]]---------------------------------------------------------
--[[
function ScrollPanel:GetScrollBar()
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
function ScrollPanel:SetAutoScroll(bool)
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
function ScrollPanel:GetAutoScroll()
	return self.autoscroll
end
]]
--[[---------------------------------------------------------
	- func: SetButtonScrollAmount(speed)
	- desc: sets the scroll amount of the object's scrollbar
			buttons
--]]---------------------------------------------------------
--[[function ScrollPanel:SetButtonScrollAmount(amount)
	self.buttonscrollamount = amount
	return self
end
]]
--[[---------------------------------------------------------
	- func: GetButtonScrollAmount()
	- desc: gets the scroll amount of the object's scrollbar
			buttons
--]]---------------------------------------------------------
--[[function ScrollPanel:GetButtonScrollAmount()
	return self.buttonscrollamount
end
]]
--[[---------------------------------------------------------
	- func: SetMouseWheelScrollAmount(amount)
	- desc: sets the scroll amount of the mouse wheel
--]]---------------------------------------------------------
function ScrollPanel:SetMouseWheelScrollAmount(amount)
	self.mousewheelscrollamount = amount
	return self
end

--[[---------------------------------------------------------
	- func: GetMouseWheelScrollAmount()
	- desc: gets the scroll amount of the mouse wheel
--]]---------------------------------------------------------
function ScrollPanel:GetMouseWheelScrollAmount()
	return self.mousewheelscrollamount
end

---------- module end ----------
end
