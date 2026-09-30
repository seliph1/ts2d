--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- list object
	local ScrollPanel = loveframes.NewObject("scrollpanel", "loveframes_object_scrollpanel", true)
	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
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
		self.mousewheelscrollamount = 20
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
		self.background = true
		self.OnScroll = nil
		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]] ---------------------------------------------------------
	function ScrollPanel:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

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
		if offsetx ~= self.last_offsetx or offsety ~= self.last_offsety or (self.itemlength == 0 and #self.children > 0) then
			scrolled = true
		end
		self.last_offsetx = offsetx
		self.last_offsety = offsety

		self:CheckHover()
		if scrolled then
			self.itemcache, self.itemlength = self.itemhash:queryRect(
				self.offsetx,
				self.offsety,
				self.width,
				self.height
			)
		end

		-- shift the panel's own position by the scroll offset while updating its
		-- items, so each item AND its descendants are positioned relative to the
		-- scrolled origin (their update does x = parent.x + staticx, which then
		-- cascades the offset down the whole subtree). restore it afterwards so
		-- drawing, click bounds and the scroll bars use the real position
		local realx, realy = self.x, self.y
		self.x = math.floor(realx - self.last_offsetx)
		self.y = math.floor(realy - self.last_offsety)

		if self.itemlength == 0 and #self.children > 0 then
			self.itemcache, self.itemlength = self.itemhash:queryRect(
				self.offsetx,
				self.offsety,
				self.width,
				self.height
			)
		end

		for i = 1, self.itemlength do
			local child = self.itemcache[i]
			child:update(dt)
			child:SetClickBounds(realx, realy, width, height)
		end

		self.x = realx
		self.y = realy

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
--]] ---------------------------------------------------------
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

		if self.itemlength == 0 and #self.children > 0 then
			self.itemcache, self.itemlength = self.itemhash:queryRect(
				self.offsetx,
				self.offsety,
				self.width,
				self.height
			)
		end

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
--]] ---------------------------------------------------------
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
--]]                             ---------------------------------------------------------
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
	- func: Fill(item, margin, align, max_per_line, overflow_policy)
	- desc: overrides Base:Fill for ScrollPanel.
			Places item into flow layout, indexes it into itemhash
			(spatial hash) for high-performance frustum culling,
			and updates extraheight / extrawidth.
			Supports overflow_policy = "scroll" (default) or "wrap".
--]] ---------------------------------------------------------
	function ScrollPanel:Fill(item_or_margin, margin_or_align, align_or_max, max_or_policy, maybe_policy)
		local panel, item, margin, align, max_per_line, overflow_policy
		if type(item_or_margin) == "table" and item_or_margin.type then
			panel = self
			item = item_or_margin
			margin = margin_or_align
			align = align_or_max
			max_per_line = max_or_policy
			overflow_policy = maybe_policy
		else
			item = self
			panel = self.parent
			margin = item_or_margin
			align = margin_or_align
			max_per_line = align_or_max
			overflow_policy = max_or_policy
		end

		if not (panel and item) or item.type == "frame" then
			return item
		end

		margin = margin or 5
		align = align or "horizontal"
		overflow_policy = overflow_policy or "scroll"

		-- Ensure item is properly reparented to the scrollpanel
		if item.parent ~= panel then
			item:Remove()
			item.parent = panel
			item:SetState(panel.state)
			table.insert(panel.children, item)
		else
			local exists = false
			for _, child in ipairs(panel.children) do
				if child == item then
					exists = true
					break
				end
			end
			if not exists then
				table.insert(panel.children, item)
			end
		end

		local usable_width = panel.width
		local usable_height = panel.height

		local state = panel._flow_state
		if not state or state.align ~= align or state.margin ~= margin or state.max_per_line ~= max_per_line then
			state = {
				x = margin,
				y = margin,
				line_size = 0,
				items_in_line = 0,
				items = {},
				align = align,
				margin = margin,
				max_per_line = max_per_line,
				overflow_policy = overflow_policy,
			}
			panel._flow_state = state
		end

		table.insert(state.items, item)

		local c_w = item.width or 0
		local c_h = item.height or 0

		if align == "horizontal" then
			if state.items_in_line > 0 then
				local wrap = false
				if state.max_per_line and state.items_in_line >= state.max_per_line then
					wrap = true
				elseif (state.x + c_w + margin) > usable_width then
					wrap = true
				end

				if wrap then
					state.x = margin
					state.y = state.y + state.line_size + margin
					state.line_size = 0
					state.items_in_line = 0
				end
			end

			local pos_x = state.x
			local pos_y = state.y

			state.x = state.x + c_w + margin
			if c_h > state.line_size then
				state.line_size = c_h
			end
			state.items_in_line = state.items_in_line + 1

			pos_x = math.floor(pos_x)
			pos_y = math.floor(pos_y)

			item.staticx = pos_x
			item.staticy = pos_y
			item.x = panel.x + pos_x
			item.y = panel.y + pos_y

			-- Spatial hash indexing for culling
			if panel.itemhash:hasItem(item) then
				panel.itemhash:update(item, pos_x, pos_y, c_w, c_h)
			else
				panel.itemhash:add(item, pos_x, pos_y, c_w, c_h)
			end

			if overflow_policy == "wrap" then
				local req_w = pos_x + c_w + margin
				local req_h = pos_y + c_h + margin
				if req_w > panel.width then
					panel:SetWidth(req_w)
				end
				if req_h > panel.height then
					panel:SetHeight(req_h)
				end
			else -- "scroll"
				local req_w = pos_x + c_w + margin
				local req_h = pos_y + c_h + margin
				if not panel.itemwidth or req_w > panel.itemwidth then
					panel.itemwidth = req_w
				end
				if not panel.itemheight or req_h > panel.itemheight then
					panel.itemheight = req_h
				end

				if panel.itemheight > panel.height then
					panel.extraheight = panel.itemheight - panel.height
					if not panel.vbar then
						local verticalbar = loveframes.objects["scrollbody"]:new(panel, "vertical")
						table.insert(panel.internals, verticalbar)
						panel.vbar = true
					end
				end

				if panel.itemwidth > panel.width then
					panel.extrawidth = panel.itemwidth - panel.width
					if not panel.hbar then
						local horizontalbar = loveframes.objects["scrollbody"]:new(panel, "horizontal")
						table.insert(panel.internals, horizontalbar)
						panel.hbar = true
					end
				end
			end
		else -- vertical
			if state.items_in_line > 0 then
				local wrap = false
				if state.max_per_line and state.items_in_line >= state.max_per_line then
					wrap = true
				elseif (state.y + c_h + margin) > usable_height then
					wrap = true
				end

				if wrap then
					state.y = margin
					state.x = state.x + state.line_size + margin
					state.line_size = 0
					state.items_in_line = 0
				end
			end

			local pos_x = state.x
			local pos_y = state.y

			state.y = state.y + c_h + margin
			if c_w > state.line_size then
				state.line_size = c_w
			end
			state.items_in_line = state.items_in_line + 1

			pos_x = math.floor(pos_x)
			pos_y = math.floor(pos_y)

			item.staticx = pos_x
			item.staticy = pos_y
			item.x = panel.x + pos_x
			item.y = panel.y + pos_y

			-- Spatial hash indexing for culling
			if panel.itemhash:hasItem(item) then
				panel.itemhash:update(item, pos_x, pos_y, c_w, c_h)
			else
				panel.itemhash:add(item, pos_x, pos_y, c_w, c_h)
			end

			if overflow_policy == "wrap" then
				local req_w = pos_x + c_w + margin
				local req_h = pos_y + c_h + margin
				if req_w > panel.width then
					panel:SetWidth(req_w)
				end
				if req_h > panel.height then
					panel:SetHeight(req_h)
				end
			else -- "scroll"
				local req_w = pos_x + c_w + margin
				local req_h = pos_y + c_h + margin
				if not panel.itemwidth or req_w > panel.itemwidth then
					panel.itemwidth = req_w
				end
				if not panel.itemheight or req_h > panel.itemheight then
					panel.itemheight = req_h
				end

				if panel.itemheight > panel.height then
					panel.extraheight = panel.itemheight - panel.height
					if not panel.vbar then
						local verticalbar = loveframes.objects["scrollbody"]:new(panel, "vertical")
						table.insert(panel.internals, verticalbar)
						panel.vbar = true
					end
				end

				if panel.itemwidth > panel.width then
					panel.extrawidth = panel.itemwidth - panel.width
					if not panel.hbar then
						local horizontalbar = loveframes.objects["scrollbody"]:new(panel, "horizontal")
						table.insert(panel.internals, horizontalbar)
						panel.hbar = true
					end
				end
			end
		end

		panel.itemcache, panel.itemlength = panel.itemhash:queryRect(
			panel.offsetx,
			panel.offsety,
			panel.width,
			panel.height
		)
		panel.last_offsetx = panel.offsetx
		panel.last_offsety = panel.offsety

		return item
	end

	--[[---------------------------------------------------------
	- func: RemoveItem(object or number)
	- desc: removes an item from the object
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
	function ScrollPanel:RedoLayout()
		local height = self.height
		local width = self.width
		local vbar = self.vbar
		local hbar = self.hbar

		local min_x, min_y, max_x, max_y = 0, 0, 0, 0
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
--]] ---------------------------------------------------------
	function ScrollPanel:Clear()
		self.itemhash:clear()
		self.children = {}
		self.itemcache = {}
		self.itemlength = 0
		self.last_offsetx = -1
		self.last_offsety = -1
		self:ResetFlow()
		self:RedoLayout()
		return self
	end

	--[[---------------------------------------------------------
	- func: GetHorizontalScrollBody() GetVerticalScrollBody()
	- desc: gets the object's scroll body
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
	function ScrollPanel:ShowBackground(bool)
		self.background = bool
		return self
	end

	ScrollPanel.SetBackground = ScrollPanel.ShowBackground
	--[[---------------------------------------------------------
	- func: GetScrollBar()
	- desc: gets the object's scroll bar
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
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
--]] ---------------------------------------------------------
	--[[
function ScrollPanel:GetAutoScroll()
	return self.autoscroll
end
]]
	--[[---------------------------------------------------------
	- func: SetButtonScrollAmount(speed)
	- desc: sets the scroll amount of the object's scrollbar
			buttons
--]] ---------------------------------------------------------
	--[[function ScrollPanel:SetButtonScrollAmount(amount)
	self.buttonscrollamount = amount
	return self
end
]]
	--[[---------------------------------------------------------
	- func: GetButtonScrollAmount()
	- desc: gets the scroll amount of the object's scrollbar
			buttons
--]] ---------------------------------------------------------
	--[[function ScrollPanel:GetButtonScrollAmount()
	return self.buttonscrollamount
end
]]
	--[[---------------------------------------------------------
	- func: SetMouseWheelScrollAmount(amount)
	- desc: sets the scroll amount of the mouse wheel
--]] ---------------------------------------------------------
	function ScrollPanel:SetMouseWheelScrollAmount(amount)
		self.mousewheelscrollamount = amount
		return self
	end

	--[[---------------------------------------------------------
	- func: GetMouseWheelScrollAmount()
	- desc: gets the scroll amount of the mouse wheel
--]] ---------------------------------------------------------
	function ScrollPanel:GetMouseWheelScrollAmount()
		return self.mousewheelscrollamount
	end

	---------- module end ----------
end
