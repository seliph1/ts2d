--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- graphnode object
local newobject = loveframes.NewObject("graphnode", "loveframes_object_graphnode", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	self.type = "graphnode"
	self.graphx = 0
	self.graphy = 0
	self.width = 160
	self.height = 60
	self.name = "Node"
	self.inputs = {}
	self.outputs = {}
	self.internals = {}
	self.dragging = false
	self.drag_offset_x = 0
	self.drag_offset_y = 0
	self.collide = true
	self.header_height = 24
	self.children = {}
	self.last_child_count = 0

	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the node and its dragging state
--]]---------------------------------------------------------
function newobject:update(dt)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	self:CheckHover()

	local parent = self.parent
	local base = loveframes.base

	-- Handle title bar dragging
	if self.dragging then
		if love.mouse.isDown(1) then
			local mx, my = love.mouse.getPosition()
			if parent and parent.type == "graphfield" then
				local gx = mx - parent.x - parent.scrollx
				local gy = my - parent.y - parent.scrolly
				self.graphx = gx - self.drag_offset_x
				self.graphy = gy - self.drag_offset_y
			else
				self.graphx = mx - self.drag_offset_x
				self.graphy = my - self.drag_offset_y
			end
		else
			self.dragging = false
		end
	end

	-- Apply parent scroll offsets
	if parent and parent.type == "graphfield" then
		self.staticx = self.graphx + parent.scrollx
		self.staticy = self.graphy + parent.scrolly
	end

	-- Base positioning relative to parent window/panel
	if parent ~= base then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end

	-- Automatically run RedoLayout if new children are parented
	if self.last_child_count ~= #self.children then
		self:RedoLayout()
		self.last_child_count = #self.children
	end

	for k, v in ipairs(self.internals) do
		v:update(dt)
	end

	for k, v in ipairs(self.children) do
		v:update(dt)
	end

	local update = self.Update
	if update then
		update(self, dt)
	end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: handles click events on the node header for dragging
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local parent = self.parent
	if self.hover and button == 1 then
		self:MoveToTop()
		
		-- Check if click is within the header bar area
		if y >= self.y and y <= self.y + self.header_height then
			self.dragging = true
			local mx, my = love.mouse.getPosition()
			if parent and parent.type == "graphfield" then
				local gx = mx - parent.x - parent.scrollx
				local gy = my - parent.y - parent.scrolly
				self.drag_offset_x = gx - self.graphx
				self.drag_offset_y = gy - self.graphy
			else
				self.drag_offset_x = mx - self.graphx
				self.drag_offset_y = my - self.graphy
			end
		end
	end

	for k, v in ipairs(self.internals) do
		v:mousepressed(x, y, button)
	end

	for k, v in ipairs(self.children) do
		v:mousepressed(x, y, button)
	end
end

--[[---------------------------------------------------------
	- func: AddInput(name, color, datatype)
	- desc: adds an input socket on the left
--]]---------------------------------------------------------
function newobject:AddInput(name, color, datatype)
	local socket = loveframes.graphsocket:new()
	socket.parent = self
	socket.sockettype = "input"
	socket.name = name or "Input"
	socket.color = color or {0.8, 0.4, 0.4, 1}
	socket.datatype = datatype or "any"
	
	table.insert(self.inputs, socket)
	table.insert(self.internals, socket)
	
	self:RedoLayout()
	return socket
end

--[[---------------------------------------------------------
	- func: AddOutput(name, color, datatype)
	- desc: adds an output socket on the right
--]]---------------------------------------------------------
function newobject:AddOutput(name, color, datatype)
	local socket = loveframes.graphsocket:new()
	socket.parent = self
	socket.sockettype = "output"
	socket.name = name or "Output"
	socket.color = color or {0.4, 0.8, 0.4, 1}
	socket.datatype = datatype or "any"
	
	table.insert(self.outputs, socket)
	table.insert(self.internals, socket)
	
	self:RedoLayout()
	return socket
end

--[[---------------------------------------------------------
	- func: RedoLayout()
	- desc: positions the sockets and resizes the node container
--]]---------------------------------------------------------
function newobject:RedoLayout()
	local num_rows = math.max(#self.inputs, #self.outputs)
	local start_y = self.header_height + 10
	local row_height = 22
	
	local required_height = start_y + num_rows * row_height + 5

	-- Automatically expand height to fit child widgets
	for _, child in ipairs(self.children) do
		local bottom = child:GetStaticY() + child:GetHeight() + 10
		if bottom > required_height then
			required_height = bottom
		end
	end
	
	self.height = math.max(60, required_height)

	-- Position inputs on the left
	for i, socket in ipairs(self.inputs) do
		local y_offset = start_y + (i - 1) * row_height
		socket:SetPos(4, y_offset)
	end

	-- Position outputs on the right
	for i, socket in ipairs(self.outputs) do
		local y_offset = start_y + (i - 1) * row_height
		socket:SetPos(self.width - 16, y_offset)
	end

	return self
end



--[[---------------------------------------------------------
	- func: MoveToTop()
	- desc: moves the node to the top of the parent graphfield children list
--]]---------------------------------------------------------
function newobject:MoveToTop()
	local parent = self.parent
	if parent then
		local children = parent.children
		for i, child in ipairs(children) do
			if child == self then
				table.remove(children, i)
				table.insert(children, self)
				break
			end
		end
	end
	
	local baseparent = self:GetBaseParent()
	if baseparent and baseparent.type == "frame" then
		baseparent:MakeTop()
	end
end


---------- module end ----------
end
