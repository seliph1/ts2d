--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- columnlistrow class
local newobject = loveframes.NewObject("columnlistrow", "loveframes_object_columnlistrow", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: intializes the element
--]]---------------------------------------------------------
function newobject:initialize(parent, data)

	self.type = "columnlistrow"
	self.parent = parent
	self.state = parent.state
	self.colorindex = self.parent.rowcolorindex
	self.font = loveframes.basicfontsmall
	self.width = 80
	self.height = 25
	self.textx = 5
	self.texty = 5
	self.selected = false
	self.internal = true
	self.columndata = {}
	self.columnchunks = {}
	
	self:ParseColumnData(data)
	
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
	
	if update then
		update(self, dt)
	end

end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button)

	if not self.visible then
		return
	end
	
	if self.hover and button == 1 then
		local baseparent = self:GetBaseParent()
		if baseparent and baseparent.type == "frame" then
			baseparent:MakeTop()
		end
		self:GetParent():GetParent():SelectRow(self, loveframes.IsCtrlDown())
	end

end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function newobject:mousereleased(x, y, button)

	if not self.visible then
		return
	end
	
	if self.hover then
		local parent = self:GetParent():GetParent()
		if button == 1 then
			local onrowclicked = parent.OnRowClicked
			if onrowclicked then
				onrowclicked(parent, self, self.columndata)
			end
		elseif button == 2 then
			local onrowrightclicked = parent.OnRowRightClicked
			if onrowrightclicked then
				onrowrightclicked(parent, self, self.columndata)
			end
		end
	end
	
end

--[[---------------------------------------------------------
	- func: SetTextPos(x, y)
	- desc: sets the positions of the object's text
--]]---------------------------------------------------------
function newobject:SetTextPos(x, y)

	self.textx = x
	self.texty = y

end

--[[---------------------------------------------------------
	- func: GetTextX()
	- desc: gets the object's text x position
--]]---------------------------------------------------------
function newobject:GetTextX()

	return self.textx

end

--[[---------------------------------------------------------
	- func: GetTextY()
	- desc: gets the object's text y position
--]]---------------------------------------------------------
function newobject:GetTextY()

	return self.texty

end

--[[---------------------------------------------------------
	- func: SetFont(font)
	- desc: sets the object's font
--]]---------------------------------------------------------
function newobject:SetFont(font)

	self.font = font

end

--[[---------------------------------------------------------
	- func: GetFont()
	- desc: gets the object's font
--]]---------------------------------------------------------
function newobject:GetFont()

	return self.font

end

--[[---------------------------------------------------------
	- func: GetColorIndex()
	- desc: gets the object's color index
--]]---------------------------------------------------------
function newobject:GetColorIndex()

	return self.colorindex

end

--[[---------------------------------------------------------
	- func: SetColumnData(data)
	- desc: sets the object's column data
--]]---------------------------------------------------------
function newobject:SetColumnData(data)

	self:ParseColumnData(data)
	
end

--[[---------------------------------------------------------
	- func: ParseColumnData(data)
	- desc: parses column data and caches color chunks/bars
--]]---------------------------------------------------------
function newobject:ParseColumnData(data)

	self.columndata = {}
	self.columnchunks = {}

	for k, v in ipairs(data) do
		local str = tostring(v)
		self.columndata[k] = str

		if str:find("©") then
			self.columnchunks[k] = self:ParseChunks(str)
		end
	end

end

--[[---------------------------------------------------------
	- func: ParseChunks(str)
	- desc: parses CS2D color tags into drawable chunks once
--]]---------------------------------------------------------
function newobject:ParseChunks(str)

	local chunks = {}
	local cur_col = { 0.8, 0.8, 0.8, 1 }
	local last = 1
	while true do
		local i, j = str:find("©", last)
		if not i then
			if #str >= last then
				table.insert(chunks, cur_col)
				table.insert(chunks, str:sub(last))
			end
			break
		end
		if i > last then
			table.insert(chunks, cur_col)
			table.insert(chunks, str:sub(last, i - 1))
		end
		local k = str:find("©", j + 1) or (#str + 1)
		local capture = str:sub(j + 1, k - 1)
		local r, g, b = capture:match("(%d%d%d)(%d%d%d)(%d%d%d)")
		local captured_text = capture:sub(10)
		if r and g and b then
			cur_col = { tonumber(r) / 255, tonumber(g) / 255, tonumber(b) / 255, 1 }
			table.insert(chunks, cur_col)
			table.insert(chunks, captured_text)
		else
			table.insert(chunks, cur_col)
			table.insert(chunks, "©" .. capture)
		end
		last = k
	end
	return chunks

end

--[[---------------------------------------------------------
	- func: GetColumnData()
	- desc: gets the object's column data
--]]---------------------------------------------------------
function newobject:GetColumnData()

	return self.columndata
	
end

--[[---------------------------------------------------------
	- func: SetSelected(selected)
	- desc: sets whether or not the object is selected
--]]---------------------------------------------------------
function newobject:SetSelected(selected)

	self.selected = true

end

--[[---------------------------------------------------------
	- func: GetSelected()
	- desc: gets whether or not the object is selected
--]]---------------------------------------------------------
function newobject:GetSelected()

	return self.selected
	
end

---------- module end ----------
end
