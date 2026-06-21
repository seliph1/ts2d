--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- columnlistarea class
local newobject = loveframes.NewObject("columnlistarea", "loveframes_object_columnlistarea", true)

--[[---------------------------------------------------------
	- row prototype
	- desc: rows are plain data tables managed by the area
	        itself, they are not loveframes UI objects
--]]---------------------------------------------------------
local rowobject = {}
rowobject.__index = rowobject

local function newrow(area, data)
	local row = setmetatable({
		type = "columnlistrow",
		parent = area,
		columndata = {},
		selected = false,
		colorindex = 1,
		font = area.font,
		width = area.parent:GetTotalColumnWidth(),
		height = area.rowheight,
		textx = 5,
		texty = 5,
		hover = false,
		-- runtime layout fields
		x = 0,
		y = 0,
		staticy = 0,
	}, rowobject)

	for k, v in ipairs(data) do
		row.columndata[k] = tostring(v)
	end

	return row
end

function rowobject:GetColumnData() return self.columndata end
function rowobject:SetColumnData(data) self.columndata = data end
function rowobject:GetColorIndex() return self.colorindex end
function rowobject:GetSelected() return self.selected end
function rowobject:SetSelected(selected) self.selected = selected end
function rowobject:GetHover() return self.hover end
function rowobject:GetFont() return self.font end
function rowobject:SetFont(font) self.font = font end
function rowobject:GetTextX() return self.textx end
function rowobject:GetTextY() return self.texty end
function rowobject:SetTextPos(x, y) self.textx = x; self.texty = y end

--[[---------------------------------------------------------
	- func: initialize()
	- desc: intializes the element
--]]---------------------------------------------------------
function newobject:initialize(parent)

	self.type = "columnlistarea"
	self.display = "vertical"
	self.parent = parent
	self.font = parent.font
	self.width = 80
	self.height = 25
	self.rowheight = 25
	self.clickx = 0
	self.clicky = 0
	self.offsety = 0
	self.offsetx = 0
	self.extrawidth = 0
	self.extraheight = 0
	self.itemwidth = 0
	self.itemheight = 0
	self.rowcolorindex = 1
	self.rowcolorindexmax = 2
	self.buttonscrollamount = parent.buttonscrollamount
	self.mousewheelscrollamount = parent.mousewheelscrollamount
	self.autoscroll = parent.autoscroll
	self.dtscrolling = parent.dtscrolling
	self.vbar = false
	self.hbar = false
	self.internal = true
	self.internals = {}
	self.children = {}
	-- rows are stored directly as data
	self.rows = {}
	self.OnScroll = nil

	-- apply template properties to the object
	loveframes.ApplyTemplatesToObject(self)
	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function newobject:update(dt)

	if not self.visible then
		if not self.alwaysupdate then
			return
		end
	end

	local parent = self.parent
	local update = self.Update

	self:CheckHover()

	-- move to parent if there is a parent
	if parent ~= loveframes.base then
		self.x = parent.x + self.staticx
		self.y = parent.y + self.staticy
	end

	-- the rows are scrolled, the header strip stays fixed at the top
	local columnheight = parent.columnheight
	local totalwidth = parent:GetTotalColumnWidth()
	local viewwidth = self.width
	local viewheight = self.height
	local vbody = self:GetVerticalScrollBody()
	local hbody = self:GetHorizontalScrollBody()
	if vbody then
		viewwidth = viewwidth - vbody.width
	end
	if hbody then
		viewheight = viewheight - hbody.height
	end

	local mx, my = love.mouse.getPosition()
	local startx = self.x - self.offsetx
	local starty = (self.y + columnheight) - self.offsety
	local insidex = self.hover and mx >= self.x and mx <= self.x + viewwidth
	local insidey = my >= self.y + columnheight and my <= self.y + viewheight

	for k, v in ipairs(self.rows) do
		v.x = startx
		v.y = starty
		v.width = totalwidth
		v.height = self.rowheight
		v.hover = insidex and insidey and my >= v.y and my < v.y + v.height
		starty = starty + v.height
	end

	-- update the scroll bodies
	for k, v in ipairs(self.internals) do
		v:update(dt)
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
	if not self:isUpdating() then return end

	self:SetDrawOrder()

	-- area background + header strip outline
	local drawfunc = self.Draw or self.drawfunc
	if drawfunc then
		drawfunc(self)
	end

	-- the rows are clipped to the scrollable region (below the header
	-- strip and excluding the scroll bars), just like scrollpanel does
	local columnheight = self.parent.columnheight
	local width = self.width
	local height = self.height
	local vbody = self:GetVerticalScrollBody()
	local hbody = self:GetHorizontalScrollBody()
	if vbody then
		width = width - vbody.width
	end
	if hbody then
		height = height - hbody.height
	end

	local skin = self:GetSkin()
	if skin.columnlistrows then
		local ox, oy, ow, oh = love.graphics.getScissor()
		love.graphics.intersectScissor(self.x, self.y + columnheight, width, height - columnheight)
		skin.columnlistrows(self)
		love.graphics.setScissor(ox, oy, ow, oh)
	end

	-- border
	drawfunc = self.DrawOver or self.drawoverfunc
	if drawfunc then
		drawfunc(self)
	end

	-- scroll bars
	for k, v in ipairs(self.internals) do
		v:draw()
	end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button)

	if self.hover and button == 1 then
		local baseparent = self:GetBaseParent()
		if baseparent and baseparent.type == "frame" then
			baseparent:MakeTop()
		end
	end

	-- scroll bars
	for k, v in ipairs(self.internals) do
		v:mousepressed(x, y, button)
	end

	-- rows
	for k, v in ipairs(self.rows) do
		if v.hover and button == 1 then
			self.parent:SelectRow(v, loveframes.IsCtrlDown())
		end
	end

end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function newobject:mousereleased(x, y, button)

	local parent = self.parent

	-- scroll bars
	for k, v in ipairs(self.internals) do
		v:mousereleased(x, y, button)
	end

	-- rows
	for k, v in ipairs(self.rows) do
		if v.hover then
			if button == 1 then
				local onrowclicked = parent.OnRowClicked
				if onrowclicked then
					onrowclicked(parent, v, v.columndata)
				end
			elseif button == 2 then
				local onrowrightclicked = parent.OnRowRightClicked
				if onrowrightclicked then
					onrowrightclicked(parent, v, v.columndata)
				end
			end
		end
	end

end

-- mouse wheel scrolling is handled by the internal scrollbody (the same
-- way scrollpanel does it), so the area does not define its own wheelmoved

--[[---------------------------------------------------------
	- func: CalculateSize()
	- desc: calculates the size of the object's rows and
	        creates/removes the scroll bars when needed
--]]---------------------------------------------------------
function newobject:CalculateSize()

	local parent = self.parent
	local height = self.height
	local width = self.width
	local itemheight = parent.columnheight

	for k, v in ipairs(self.rows) do
		itemheight = itemheight + v.height
	end

	self.itemheight = itemheight
	self.itemwidth = parent:GetTotalColumnWidth()

	-- vertical scroll bar
	local hbarheight = 0
	local hbody = self:GetHorizontalScrollBody()
	if hbody then
		hbarheight = hbody.height
	end

	if self.itemheight > (height - hbarheight) then
		if hbody then
			self.itemheight = self.itemheight + hbarheight
		end
		self.extraheight = self.itemheight - height
		if not self.vbar then
			local newbar = loveframes.objects["scrollbody"]:new(self, "vertical")
			table.insert(self.internals, newbar)
			self.vbar = true
			newbar:GetScrollBar().autoscroll = parent.autoscroll
			self.itemwidth = self.itemwidth + newbar.width
			self.extrawidth = self.itemwidth - width
		end
	else
		local vbar = self:GetVerticalScrollBody()
		if vbar then
			vbar:Remove()
			self.vbar = false
			self.offsety = 0
		end
	end

	-- horizontal scroll bar
	local vbarwidth = 0
	local vbody = self:GetVerticalScrollBody()
	if vbody then
		vbarwidth = vbody.width
	end

	if self.itemwidth > (width - vbarwidth) then
		if vbody then
			self.itemwidth = self.itemwidth + vbarwidth
		end
		self.extrawidth = self.itemwidth - width
		if not self.hbar then
			local newbar = loveframes.objects["scrollbody"]:new(self, "horizontal")
			table.insert(self.internals, newbar)
			self.hbar = true
			self.itemheight = self.itemheight + newbar.height
			self.extraheight = self.itemheight - height
		end
	else
		local hbar = self:GetHorizontalScrollBody()
		if hbar then
			hbar:Remove()
			self.itemheight = self.itemheight - hbar.height
			self.extraheight = self.itemheight - height
			self.hbar = false
			self.offsetx = 0
		end
	end

end

--[[---------------------------------------------------------
	- func: RedoLayout()
	- desc: used to redo the layout of the object
--]]---------------------------------------------------------
function newobject:RedoLayout()

	local starty = 0
	local totalwidth = self.parent:GetTotalColumnWidth()
	self.rowcolorindex = 1

	for k, v in ipairs(self.rows) do
		v.width = totalwidth
		v.staticy = starty
		starty = starty + v.height
		v.colorindex = self.rowcolorindex
		if self.rowcolorindex == self.rowcolorindexmax then
			self.rowcolorindex = 1
		else
			self.rowcolorindex = self.rowcolorindex + 1
		end
	end

end

--[[---------------------------------------------------------
	- func: AddRow(data)
	- desc: adds a row to the object
--]]---------------------------------------------------------
function newobject:AddRow(data)

	table.insert(self.rows, newrow(self, data))
	self:CalculateSize()
	self:RedoLayout()
	self.parent:PositionColumns()

end

--[[---------------------------------------------------------
	- func: RemoveRow(id)
	- desc: removes a row from the object
--]]---------------------------------------------------------
function newobject:RemoveRow(id)

	if self.rows[id] then
		table.remove(self.rows, id)
		self:CalculateSize()
		self:RedoLayout()
	end

end

--[[---------------------------------------------------------
	- func: Sort(column, desc)
	- desc: sorts the object's rows
--]]---------------------------------------------------------
function newobject:Sort(column, desc)

	local rows = self.rows
	self.rowcolorindex = 1

	table.sort(rows, function(a, b)
		if desc then
			return (tostring(a.columndata[column]) or a.columndata[column]) < (tostring(b.columndata[column]) or b.columndata[column])
		else
			return (tostring(a.columndata[column]) or a.columndata[column]) > (tostring(b.columndata[column]) or b.columndata[column])
		end
	end)

	for k, v in ipairs(rows) do
		local colorindex = self.rowcolorindex
		v.colorindex = colorindex
		if colorindex == self.rowcolorindexmax then
			self.rowcolorindex = 1
		else
			self.rowcolorindex = colorindex + 1
		end
	end

	self:CalculateSize()
	self:RedoLayout()

end

--[[---------------------------------------------------------
	- func: Clear()
	- desc: removes all rows from the object
--]]---------------------------------------------------------
function newobject:Clear()

	self.rows = {}
	self:CalculateSize()
	self:RedoLayout()
	self.parent:PositionColumns()
	self.rowcolorindex = 1

end

--[[---------------------------------------------------------
	- func: SetFont(font)
	- desc: sets the font used by the rows
--]]---------------------------------------------------------
function newobject:SetFont(font)

	self.font = font

	for k, v in ipairs(self.rows) do
		v.font = font
	end

	return self

end

--[[---------------------------------------------------------
	- func: GetFont()
	- desc: gets the font used by the rows
--]]---------------------------------------------------------
function newobject:GetFont()

	return self.font

end

--[[---------------------------------------------------------
	- func: GetRows()
	- desc: gets the object's rows
--]]---------------------------------------------------------
function newobject:GetRows()

	return self.rows

end

--[[---------------------------------------------------------
	- func: GetScrollBar()
	- desc: gets the object's active scroll bar
--]]---------------------------------------------------------
function newobject:GetScrollBar()

	local vbody = self:GetVerticalScrollBody()
	local hbody = self:GetHorizontalScrollBody()

	if vbody then
		return vbody:GetScrollBar()
	elseif hbody then
		return hbody:GetScrollBar()
	end

	return nil

end

--[[---------------------------------------------------------
	- func: GetVerticalScrollBody()
	- desc: gets the object's vertical scroll body
--]]---------------------------------------------------------
function newobject:GetVerticalScrollBody()

	for k, v in ipairs(self.internals) do
		if v.bartype == "vertical" then
			return v
		end
	end

	return nil

end

--[[---------------------------------------------------------
	- func: GetHorizontalScrollBody()
	- desc: gets the object's horizontal scroll body
--]]---------------------------------------------------------
function newobject:GetHorizontalScrollBody()

	for k, v in ipairs(self.internals) do
		if v.bartype == "horizontal" then
			return v
		end
	end

	return nil

end

---------- module end ----------
end
