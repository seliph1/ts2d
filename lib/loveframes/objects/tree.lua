--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- tree object
	local newobject = loveframes.NewObject("tree", "loveframes_object_tree", true)

	--[[---------------------------------------------------------
	- node prototype
	- desc: nodes are plain data tables managed by the tree
	        itself, they are not loveframes UI objects
--]] ---------------------------------------------------------
	local treenode = {}
	treenode.__index = treenode

	local function newnode(tree, parent, text, level)
		return setmetatable({
			type = "treenode",
			tree = tree,
			parent = parent,
			text = text,
			level = level,
			open = false,
			icon = nil,
			children = {},
			lastclick = 0,
			OnOpen = nil,
			OnClose = nil,
			-- runtime layout fields (filled by tree:CalculateLayout)
			x = 0,
			y = 0,
			width = 0,
			height = 0,
		}, treenode)
	end

	local function removeNodeFromParent(node)
		local p = node.parent
		local list = (p.type == "tree") and p.nodes or p.children
		for i, v in ipairs(list) do
			if v == node then
				table.remove(list, i)
				node.tree.layout_dirty = true
				return i
			end
		end
		return nil
	end

	local function insertNode(node, target_parent, index)
		local list = (target_parent.type == "tree") and target_parent.nodes or target_parent.children
		table.insert(list, index, node)
		node.parent = target_parent
		node.tree.layout_dirty = true
		local function updateLevel(n, level)
			n.level = level
			for _, c in ipairs(n.children) do
				updateLevel(c, level + 1)
			end
		end
		updateLevel(node, target_parent.type == "tree" and 0 or target_parent.level + 1)
	end

	--[[---------------------------------------------------------
	- func: node:AddNode(text)
	- desc: adds a child node to this node
--]] ---------------------------------------------------------
	function treenode:AddNode(text)
		local node = newnode(self.tree, self, text, self.level + 1)
		table.insert(self.children, node)
		self.tree.layout_dirty = true
		return node
	end

	--[[---------------------------------------------------------
	- func: node:RemoveNode(id)
	- desc: removes a child node from this node
--]] ---------------------------------------------------------
	function treenode:RemoveNode(id)
		if self.children[id] then
			if self.tree.selectednode == self.children[id] then
				self.tree.selectednode = false
			end
			table.remove(self.children, id)
			self.tree.layout_dirty = true
		end
	end

	--[[---------------------------------------------------------
	- func: node:SetOpen(bool) / node:GetOpen()
	- desc: sets/gets whether or not the node is open
--]] ---------------------------------------------------------
	function treenode:SetOpen(bool)
		self.open = bool
		return self
	end

	function treenode:GetOpen()
		return self.open
	end

	--[[---------------------------------------------------------
	- func: node:SetText(text) / node:GetText()
	- desc: sets/gets the node's text
--]] ---------------------------------------------------------
	function treenode:SetText(text)
		self.text = text
		return self
	end

	function treenode:GetText()
		return self.text
	end

	--[[---------------------------------------------------------
	- func: node:SetIcon(icon) / node:GetIcon()
	- desc: sets/gets the node's icon
--]] ---------------------------------------------------------
	function treenode:SetIcon(icon)
		if type(icon) == "string" then
			self.icon = love.graphics.newImage(icon)
			self.icon:setFilter("nearest", "nearest")
		else
			self.icon = icon
		end
		return self
	end

	function treenode:GetIcon()
		return self.icon
	end

	--[[---------------------------------------------------------
	- func: flatten(node, list)
	- desc: appends a node and its open descendants to list
	        in pre-order (the order they are displayed)
--]] ---------------------------------------------------------
	local function flatten(node, list)
		list[#list + 1] = node
		if node.open then
			for _, child in ipairs(node.children) do
				flatten(child, list)
			end
		end
	end

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function newobject:initialize()
		local skin = loveframes.GetActiveSkin()
		local font = skin.directives.text_default_font or loveframes.basicfont

		self.type = "tree"
		self.font = font
		self.width = 200
		self.height = 200
		self.offsetx = 0
		self.offsety = 0
		self.itemwidth = 0
		self.itemheight = 0
		self.buttonscrollamount = 1
		self.mousewheelscrollamount = 1
		self.internal = false
		self.selectednode = false
		self.OnSelectNode = nil
		self.children = {}
		self.internals = {}
		-- node data managed directly by the tree
		self.nodes = {}
		self.visiblenodes = {}
		-- layout metrics (buttonsize matches the 11x11 button images)
		-- rowheight is recalculated from the font in CalculateLayout
		self.cellpadding = 4
		self.rowheight = font:getHeight() + self.cellpadding
		self.indent = 15
		self.buttonsize = 11

		self.rearrange_enabled = true
		self.nesting = true
		self.layout_dirty = true
		self.last_x = 0
		self.last_y = 0
		self.last_offsety = 0
		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: CalculateLayout()
	- desc: flattens the visible nodes and computes the
	        screen geometry the skin needs to draw them
--]] ---------------------------------------------------------
	function newobject:CalculateLayout()
		local visible = {}
		for _, node in ipairs(self.nodes) do
			flatten(node, visible)
		end
		self.visiblenodes = visible

		local font = self.font
		local indent = self.indent
		local buttonsize = self.buttonsize
		-- row height follows the font height (plus padding), but never
		-- smaller than the open/close button so it stays clickable
		local rowheight = math.max(font:getHeight() + self.cellpadding, buttonsize)
		self.rowheight = rowheight
		local itemheight = 0
		local itemwidth = 0

		for _, node in ipairs(visible) do
			local leftpadding = indent * node.level
			if node.level > 0 then
				leftpadding = leftpadding + buttonsize + 5
			else
				leftpadding = buttonsize + 5
			end

			local iconwidth = 0
			local iconheight = 0
			if node.icon then
				iconwidth = node.icon:getWidth()
				iconheight = node.icon:getHeight()
			end

			node.x = self.x - self.offsetx
			node.y = (self.y + itemheight) - self.offsety
			node.height = rowheight
			node.iconwidth = iconwidth
			-- vertically center the contents within the row
			node.iconx = node.x + leftpadding
			node.icony = node.y + (rowheight - iconheight) / 2
			node.textx = node.x + leftpadding + 2 + iconwidth
			node.texty = node.y + (rowheight - font:getHeight()) / 2
			node.buttonx = node.x + 2 + indent * node.level
			node.buttony = node.y + (rowheight - buttonsize) / 2
			node.haschildren = #node.children > 0
			node.width = iconwidth + font:getWidth(node.text) + leftpadding + 5

			if node.width > itemwidth then
				itemwidth = node.width
			end
			itemheight = itemheight + node.height
		end

		self.itemwidth = itemwidth
		self.itemheight = itemheight
		self.height = math.max(itemheight, 50)


		local parent = self.parent
		if parent and parent.RedoLayout then
			parent:RedoLayout()
		end
	end

	--[[---------------------------------------------------------
	- func: ToggleNode(node)
	- desc: opens/closes a node and fires its callbacks
--]] ---------------------------------------------------------
	function newobject:ToggleNode(node)
		local open = not node.open
		if open then
			if node.OnOpen then
				node.OnOpen(node)
			end
		else
			if node.OnClose then
				node.OnClose(node)
			end
		end
		node.open = open
		self.layout_dirty = true
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]] ---------------------------------------------------------
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

		if self.layout_dirty or self.x ~= self.last_x or self.y ~= self.last_y or self.offsety ~= self.last_offsety then
			self:CalculateLayout()
			self.last_x = self.x
			self.last_y = self.y
			self.last_offsety = self.offsety
			self.layout_dirty = false
		end

		if self.rearrange_enabled and love.mouse.isDown(1) and self.down_node then
			local _, my = love.mouse.getPosition()
			if math.abs(my - self.down_y) > 5 then
				self.dragging = self.down_node
			end
		else
			self.down_node = nil
			self.dragging = nil
		end

		if self.dragging then
			local _, my = love.mouse.getPosition()
			self.drop_target = nil
			self.drop_pos = nil
			if self.visiblenodes then
				for _, node in ipairs(self.visiblenodes) do
					if my >= node.y and my <= node.y + node.height then
						self.drop_target = node
						if self.nesting then
							if my < node.y + node.height * 0.25 then
								self.drop_pos = "before"
							elseif my > node.y + node.height * 0.75 then
								self.drop_pos = "after"
							else
								self.drop_pos = "inside"
							end
						else
							if my < node.y + node.height * 0.5 then
								self.drop_pos = "before"
							else
								self.drop_pos = "after"
							end
						end
						break
					end
				end
			end
		end

		if update then
			update(self, dt)
		end
	end

	--[[---------------------------------------------------------
	- func: draw()
	- desc: draws the object
--]] ---------------------------------------------------------
	function newobject:draw()
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		self:SetDrawOrder()
		local drawfunc = self.Draw or self.drawfunc
		if drawfunc then
			drawfunc(self)
		end

		if self.dragging and self.drop_target then
			local tnode = self.drop_target
			love.graphics.setColor(1, 0, 0, 1)
			if self.drop_pos == "before" then
				love.graphics.rectangle("fill", tnode.x, tnode.y - 1, tnode.width, 2)
			elseif self.drop_pos == "after" then
				love.graphics.rectangle("fill", tnode.x, tnode.y + tnode.height - 1, tnode.width, 2)
			elseif self.drop_pos == "inside" then
				love.graphics.setColor(1, 0, 0, 0.2)
				love.graphics.rectangle("fill", tnode.x, tnode.y, tnode.width, tnode.height)
				love.graphics.setColor(1, 0, 0, 1)
				love.graphics.setLineWidth(2)
				love.graphics.rectangle("line", tnode.x, tnode.y, tnode.width, tnode.height)
				love.graphics.setLineWidth(1)
			end
		end
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]] ---------------------------------------------------------
	function newobject:mousepressed(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		if not self.hover then return end

		local buttonsize = self.buttonsize
		for _, node in ipairs(self.visiblenodes) do
			if y >= node.y and y < node.y + node.height then
				if button == 1 then
					-- open/close button area
					if node.haschildren
						and x >= node.buttonx and x <= node.buttonx + buttonsize
						and y >= node.buttony and y <= node.buttony + buttonsize then
						self:ToggleNode(node)
					else
						self.down_node = node
						self.down_y = y
						-- node selection (double click toggles)
						local time = love.timer.getTime()
						if node.lastclick + 0.40 > time then
							self:ToggleNode(node)
						end
						node.lastclick = time
						self.selectednode = node
						local onselectnode = self.OnSelectNode
						if onselectnode then
							onselectnode(node.parent, node)
						end
					end
				elseif button == 2 then
					self.selectednode = node
					local onrightclick = self.OnRightClickNode
					if onrightclick then
						onrightclick(node.parent, node, x, y)
					end
				end
				break
			end
		end
	end

	--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]] ---------------------------------------------------------
	function newobject:mousereleased(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		if button == 1 and self.dragging and self.drop_target then
			local valid = true
			local curr = self.drop_target
			while curr and curr.type == "treenode" do
				if curr == self.dragging then
					valid = false; break
				end
				curr = curr.parent
			end

			if valid and self.drop_target ~= self.dragging then
				local old_parent = self.dragging.parent
				local list = (self.drop_target.parent.type == "tree") and self.drop_target.parent.nodes or
					self.drop_target.parent.children
				local target_index = 1
				for i, v in ipairs(list) do
					if v == self.drop_target then
						target_index = i; break
					end
				end

				local tp = self.drop_target.parent
				if self.drop_pos == "after" then
					target_index = target_index + 1
				elseif self.drop_pos == "inside" then
					tp = self.drop_target
					target_index = #tp.children + 1
					tp.open = true
				end

				removeNodeFromParent(self.dragging)

				if tp == old_parent then
					local new_idx = 1
					if self.drop_pos == "inside" then
						new_idx = #tp.children + 1
					else
						local found_target = false
						local t_list = (tp.type == "tree") and tp.nodes or tp.children
						for i, v in ipairs(t_list) do
							if v == self.drop_target then
								new_idx = (self.drop_pos == "after") and (i + 1) or i
								found_target = true
								break
							end
						end
						if not found_target then new_idx = #t_list + 1 end
					end
					target_index = new_idx
				end

				insertNode(self.dragging, tp, target_index)

				if self.OnNodeDropped then
					self.OnNodeDropped(self, self.dragging, tp, target_index)
				end
			end
		end

		self.down_node = nil
		self.dragging = nil
		self.drop_target = nil
	end

	--[[---------------------------------------------------------
	- func: AddNode(text)
	- desc: adds a root node to the object
--]] ---------------------------------------------------------
	function newobject:AddNode(text)
		local node = newnode(self, self, text, 0)
		table.insert(self.nodes, node)
		self.layout_dirty = true
		return node
	end

	--[[---------------------------------------------------------
	- func: RemoveNode(id)
	- desc: removes a root node from the object
--]] ---------------------------------------------------------
	function newobject:RemoveNode(id)
		if self.nodes[id] then
			if self.selectednode == self.nodes[id] then
				self.selectednode = false
			end
			table.remove(self.nodes, id)
			self.layout_dirty = true
		end
	end

	--[[---------------------------------------------------------
	- func: GetNodes()
	- desc: gets the object's root nodes
--]] ---------------------------------------------------------
	function newobject:GetNodes()
		return self.nodes
	end

	--[[---------------------------------------------------------
	- func: SetFont(font)
	- desc: sets the font used to draw the nodes
--]] ---------------------------------------------------------
	function newobject:SetFont(font)
		self.font = font
		return self
	end

	--[[---------------------------------------------------------
	- func: GetFont()
	- desc: gets the font used to draw the nodes
--]] ---------------------------------------------------------
	function newobject:GetFont()
		return self.font
	end

	--[[---------------------------------------------------------
	- func: SetRearrangeEnabled(bool)
	- desc: sets whether drag-and-drop node rearrangement is enabled
--]] ---------------------------------------------------------
	function newobject:SetRearrangeEnabled(bool)
		self.rearrange_enabled = bool
		return self
	end

	--[[---------------------------------------------------------
	- func: GetRearrangeEnabled()
	- desc: gets whether drag-and-drop node rearrangement is enabled
--]] ---------------------------------------------------------
	function newobject:GetRearrangeEnabled()
		return self.rearrange_enabled
	end

	--[[---------------------------------------------------------
	- func: SetAllowDragInside(bool)
	- desc: sets whether dragging nodes inside other nodes is allowed
--]] ---------------------------------------------------------
	function newobject:SetNesting(bool)
		self.nesting = bool
		return self
	end

	--[[---------------------------------------------------------
	- func: GetAllowDragInside()
	- desc: gets whether dragging nodes inside other nodes is allowed
--]] ---------------------------------------------------------
	function newobject:GetNesting()
		return self.nesting
	end

	---------- module end ----------
end
