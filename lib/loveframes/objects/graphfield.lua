--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- graphfield object
	local newobject = loveframes.NewObject("graphfield", "loveframes_object_graphfield", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function newobject:initialize()
		self.type = "graphfield"
		self.width = 400
		self.height = 300
		self.scrollx = 0
		self.scrolly = 0
		self.panning = false
		self.pan_start_x = 0
		self.pan_start_y = 0
		self.connections = {}

		self.drag_src_socket = nil
		self.internal = false
		self.internals = {}
		self.children = {}
		self.collide = true

		-- Spatial hashing with bump.lua for node culling
		self.bump_world = loveframes.bump.newWorld(64)
		self.visible_nodes = {}
		self.visible_len = 0

		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates panning state and synchronizes bump spatial hashing
--]] ---------------------------------------------------------
	function newobject:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		self:CheckHover()

		local mx, my = love.mouse.getPosition()

		-- Handle panning with right (2) or middle (3) click
		if self.panning then
			local r_down = love.mouse.isDown(2)
			local m_down = love.mouse.isDown(3)
			if r_down or m_down then
				self.scrollx = mx - self.pan_start_x
				self.scrolly = my - self.pan_start_y
			else
				self.panning = false
			end
		end

		-- Base positioning
		local parent = self.parent
		local base = loveframes.base
		if parent ~= base then
			self.x = self.parent.x + self.staticx
			self.y = self.parent.y + self.staticy
		end

		-- Sync bump.lua world with node children list
		local items, len = self.bump_world:getItems()
		for i = 1, len do
			local item = items[i]
			local found = false
			for _, child in ipairs(self.children) do
				if child == item then
					found = true
					break
				end
			end
			if not found then
				self.bump_world:remove(item)
			end
		end

		for _, child in ipairs(self.children) do
			if child.type == "graphnode" then
				if not self.bump_world:hasItem(child) then
					self.bump_world:add(child, child.graphx, child.graphy, child.width, child.height)
				else
					self.bump_world:update(child, child.graphx, child.graphy, child.width, child.height)
				end
			end
		end

		-- Query spatial hash to find visible nodes
		self.visible_nodes, self.visible_len = self.bump_world:queryRect(-self.scrollx, -self.scrolly, self.width,
			self.height)

		-- Update only visible nodes
		local updated = {}
		for i = 1, self.visible_len do
			local child = self.visible_nodes[i]
			child:update(dt)
			updated[child] = true
		end

		-- Always update dragging nodes even if they move off-screen
		for _, child in ipairs(self.children) do
			if child.type == "graphnode" and child.dragging and not updated[child] then
				child:update(dt)
			end
		end

		local update = self.Update
		if update then
			update(self, dt)
		end
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: triggers camera panning
--]] ---------------------------------------------------------
	function newobject:mousepressed(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		-- Panning triggers on empty grid space clicks
		if self.hover and (button == 2 or button == 3) then
			-- Ensure no visible child node is hovered before starting field pan
			local child_hovered = false
			for i = 1, self.visible_len do
				local child = self.visible_nodes[i]
				if child.hover then
					child_hovered = true
					break
				end
			end

			if not child_hovered then
				self.panning = true
				local mx, my = love.mouse.getPosition()
				self.pan_start_x = mx - self.scrollx
				self.pan_start_y = my - self.scrolly
			end
		end

		-- Propagate only to visible nodes
		for i = 1, self.visible_len do
			local child = self.visible_nodes[i]
			child:mousepressed(x, y, button)
		end
	end

	--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: checks collision for completing socket connection drags
--]] ---------------------------------------------------------
	function newobject:mousereleased(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		-- Check if connection drag has ended
		if self.drag_src_socket and button == 1 then
			local hover_socket = nil
			for i = 1, self.visible_len do
				local child = self.visible_nodes[i]
				if child.type == "graphnode" then
					for _, socket in ipairs(child.internals) do
						if socket.type == "graphsocket" and socket.hover then
							hover_socket = socket
							break
						end
					end
				end
				if hover_socket then break end
			end

			if hover_socket then
				local src = self.drag_src_socket
				-- Validate connection: different nodes and input/output matching
				local valid_node_and_type = (src.parent ~= hover_socket.parent) and (src.sockettype ~= hover_socket.sockettype)
				local valid_datatype = (src.datatype == "any") or (hover_socket.datatype == "any") or (src.datatype == hover_socket.datatype)
				
				if valid_node_and_type and valid_datatype then
					local from = (src.sockettype == "output") and src or hover_socket
					local to = (src.sockettype == "input") and src or hover_socket
					self:Connect(from, to)
				end
			end
			self.drag_src_socket = nil
		end

		-- Propagate only to visible nodes
		for i = 1, self.visible_len do
			local child = self.visible_nodes[i]
			child:mousereleased(x, y, button)
		end
	end

	--[[---------------------------------------------------------
	- func: StartConnecting(socket)
	- desc: stores the socket connection start point
--]] ---------------------------------------------------------
	function newobject:StartConnecting(socket)
		self.drag_src_socket = socket
	end

	--[[---------------------------------------------------------
	- func: Connect(from_socket, to_socket)
	- desc: adds connection and clears old input socket mappings
--]] ---------------------------------------------------------
	function newobject:Connect(from_socket, to_socket)
		-- Remove any existing connection to this specific input socket
		self:DisconnectInput(to_socket)
		table.insert(self.connections, { from = from_socket, to = to_socket })
	end

	--[[---------------------------------------------------------
	- func: DisconnectInput(socket)
	- desc: clears existing connections mapped to target socket
--]] ---------------------------------------------------------
	function newobject:DisconnectInput(socket)
		for i = #self.connections, 1, -1 do
			if self.connections[i].to == socket then
				table.remove(self.connections, i)
			end
		end
	end

	--[[---------------------------------------------------------
	- func: DisconnectOutput(socket)
	- desc: clears existing connections mapped from target output socket
--]] ---------------------------------------------------------
	function newobject:DisconnectOutput(socket)
		for i = #self.connections, 1, -1 do
			if self.connections[i].from == socket then
				table.remove(self.connections, i)
			end
		end
	end

	--[[---------------------------------------------------------
	- func: IsSocketConnected(socket)
	- desc: returns if socket has active connections
--]] ---------------------------------------------------------
	function newobject:IsSocketConnected(socket)
		for _, conn in ipairs(self.connections) do
			if conn.from == socket or conn.to == socket then
				return true
			end
		end
		return false
	end

	--[[---------------------------------------------------------
	- func: draw()
	- desc: custom draw wrapper implementing scissor clipping and visible children culling
--]] ---------------------------------------------------------
	function newobject:draw()
		if not self:OnState() then return end
		if not self:IsVisible() then return end

		self:SetDrawOrder()
		local drawfunc = self.Draw or self.drawfunc
		local x, y = self:GetPos()
		local w, h = self:GetSize()

		-- Set scissor for clipping inside the field
		local ox, oy, ow, oh = love.graphics.getScissor()
		love.graphics.intersectScissor(x, y, w, h)

		-- Draw background, grid, connections
		if drawfunc then
			drawfunc(self)
		end

		-- Draw only culled visible nodes
		for i = 1, self.visible_len do
			local child = self.visible_nodes[i]
			child:draw()
		end

		-- Reset scissor
		love.graphics.setScissor(ox, oy, ow, oh)

		-- Draw internals
		local internals = self.internals
		if internals then
			for k, v in pairs(internals) do
				v:draw()
			end
		end

		local drawoverfunc = self.DrawOver or self.drawoverfunc
		if drawoverfunc then
			drawoverfunc(self)
		end
	end

	---------- module end ----------
end
