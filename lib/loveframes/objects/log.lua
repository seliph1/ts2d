--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- log panel that self-contains itself?
local newobject = loveframes.NewObject("log", "loveframes_object_log", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------

function newobject:initialize()
	-- Font properties
	local skin = loveframes.GetActiveSkin()
	local font = skin.directives.text_default_font or loveframes.basicfont
	--local color = skin.directives.text_default_color
	local color

	self.type = "log"
	self.width = 200
	self.height = 50
	self.internal = false
	self.children = {}
    self.internals = {}
	self.elements = {}
	self.padding = 5
	self.selected = 0
	self.hovered = 0
	self.spacing = 0
	self.background = nil
	self.font = font
	self.texthash = love.graphics.newText(font)
	self.defaultcolor = color or {1,1,1,1}
	self:SetDrawFunc()
	self.cursor = loveframes.cursors.ibeam

	local verticalbody = loveframes.objects["scrollbody"]:new(self, "vertical")
	table.insert(self.internals, verticalbody)
	self.verticalbody = verticalbody

	self.itemwidth = self.width
	self.itemheight = self.height
    self.extraheight = 0
    self.extrawidth = 0
	self.offsety = 0
	self.offsetx = 0
	self.buttonscrollamount = 1
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the element
--]]---------------------------------------------------------
function newobject:update(dt)
	local state = loveframes.state
	local selfstate = self.state
	if state ~= selfstate then
		return
	end
	local visible = self.visible
	local alwaysupdate = self.alwaysupdate
	if not visible then
		if not alwaysupdate then
			return
		end
	end
	local internals = self.internals
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update
	-- move to parent if there is a parent
	if parent ~= base then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end

	self:CheckHover()
    for _, internal in ipairs(internals) do
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
	if loveframes.state ~= self.state then
		return
	end
	if not self.visible then
		return
	end
	local x = self.x
	local y = self.y
	local width = self.width
	local height = self.height
	local drawfunc = self.Draw or self.drawfunc
	local drawoverfunc = self.DrawOver or self.drawoverfunc
	local internals = self.internals
	love.graphics.setScissor(x, y, width, height)
	if drawfunc then
		drawfunc(self)
	end
	love.graphics.setScissor()
	if drawoverfunc then
		drawoverfunc(self)
	end
	for k, v in ipairs(internals) do
		v:draw()
	end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button)
	local state = loveframes.state
	local selfstate = self.state
	if state ~= selfstate then
		return
	end
	local visible = self.visible
	if not visible then
		return
	end
	for k, v in ipairs(self.internals) do
		v:mousepressed(x, y, button)
	end
	if not self.hover then
		-- Dont select, but dont deselect also
		return
	end
	-- Retrieve the cell size
	local cell_x = self.width
	local cell_y = self.font:getHeight() + self.padding

	-- Get the relative position from mouse
	local rel_x = x - self.x
	local rel_y = y - self.y

	-- Chech which cell is selected
	-- Ceil is used so it always return element id >= 1
	local element_id = math.ceil( rel_y /  cell_y )
	if element_id < 0 or element_id > #self.elements then
		element_id = 0
	end
	self.selected = element_id
end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function newobject:mousereleased(x, y, button)
	local state = loveframes.state
	local selfstate = self.state
	if state ~= selfstate then
		return
	end
	local visible  = self.visible
	local children = self.children
	if not visible then
		return
	end
	for k, v in ipairs(self.internals) do
		v:mousereleased(x, y, button)
	end
end
--[[---------------------------------------------------------
	- func: wheelmoved(x, y)
	- desc: called when the player moves a mouse wheel
--]]---------------------------------------------------------
function newobject:wheelmoved(x, y)
	if loveframes.state ~= self.state then
		return
	end
	if not self.visible then
		return
	end
	for k, v in ipairs(self.internals) do
		v:wheelmoved(x, y)
	end
end
--[[---------------------------------------------------------
	- func: RedoLayout()
	- desc: redo the layout of the scrollpane
--]]---------------------------------------------------------
function newobject:RedoLayout()
	local elements = self.elements
	local fontheight = self.font:getHeight()

    self.itemwidth = self.width
    self.itemheight = (fontheight + self.padding) * #elements--math.max(self.height, (fontheight + self.padding) * #elements)
    self.extraheight = self.itemheight - self.height
    self.extrawidth = self.itemwidth - self.width
end

--[[---------------------------------------------------------
	- func: AddElement()
	- desc: add an element into the list
--]]---------------------------------------------------------
function newobject:AddElement(item, append)
	if type(item) == "string" then
		table.insert(self.elements, item)
		if append then
			self:AppendElement(item)
		else
			self:ParseElements()
		end
	end
end

function newobject:AddElementsFromTable(tbl)
	local validElements = 0
	for _, item in ipairs(tbl) do
		if type(item) == "string" then
			table.insert(self.elements, item)
			validElements = validElements + 1
		end
	end
	if validElements > 0 then
		self:ParseElements()
	end
end

--[[---------------------------------------------------------
	- func: ParseElements
	- desc: put the elements into a list
--]]---------------------------------------------------------
function newobject:fixUTF8(s, replacement)
  local p, len, invalid = 1, #s, {}
  while p <= len do
    if     p == s:find("[%z\1-\127]", p) then p = p + 1
    elseif p == s:find("[\194-\223][\128-\191]", p) then p = p + 2
    elseif p == s:find(       "\224[\160-\191][\128-\191]", p)
        or p == s:find("[\225-\236][\128-\191][\128-\191]", p)
        or p == s:find(       "\237[\128-\159][\128-\191]", p)
        or p == s:find("[\238-\239][\128-\191][\128-\191]", p) then p = p + 3
    elseif p == s:find(       "\240[\144-\191][\128-\191][\128-\191]", p)
        or p == s:find("[\241-\243][\128-\191][\128-\191][\128-\191]", p)
        or p == s:find(       "\244[\128-\143][\128-\191][\128-\191]", p) then p = p + 4
    else
      s = s:sub(1, p-1)..replacement..s:sub(p+1)
      table.insert(invalid, p)
    end
  end
  return s, invalid
end

function newobject:ParseText(str)
	local formattedchunks = {}
	local formattedstring = {}
    local defaultColor = self.defaultcolor

	if not str:find("©") then
		return {defaultColor,str}, str
	end

	for leading, capture in string.gmatch(str, "(.-)©([^©]+)") do
		if leading then
			table.insert(formattedchunks, defaultColor)
			table.insert(formattedchunks, leading)
			table.insert(formattedstring, leading)
		end	
		local r, g, b = string.match(capture, "(%d%d%d)(%d%d%d)(%d%d%d)")
		local text = string.sub(capture, 10, -1)
		if r and g and b then
			table.insert(formattedchunks,
				{tonumber(r)/255, tonumber(g)/255, tonumber(b)/255}
			)
			table.insert(formattedchunks, text)
			table.insert(formattedstring, text)
		else
			text = "©"..capture
		end
	end

	return formattedchunks, table.concat(formattedstring)
end

function newobject:ParseElements()
	self.texthash:clear()
	local elements = self.elements
	local maxwidth = 0
	local fontheight = self.font:getHeight()
	for index, value in ipairs(elements) do
		local parsedvalue = ""
		-- Fix the text
		value = self:fixUTF8(value, " ")

		-- Parse the obtained string with cs2d formatting
		value, parsedvalue = self:ParseText(value)

		-- Calculate height position of the line
		local height = (index-1) * (fontheight + self.padding)

		-- Calculate total wideness of the line
		local width = self.font:getWidth(parsedvalue)

		-- Resize the max width to update the layout
		if width > maxwidth then
			maxwidth = width
		end

		-- Add the fixed, formatted text to the texthash
		self.texthash:add(value, 0, height + self.padding/2)
	end
	self:RedoLayout()

	local scrollbar = self.verticalbody:GetScrollBar()
	if scrollbar then
		scrollbar:ScrollBottom()
	end
end

function newobject:AppendElement(value)
	local elements = self.elements
	local maxwidth = 0
	local fontheight = self.font:getHeight()

	local parsedvalue = ""
	-- Fix the text
	value = self:fixUTF8(value, " ")

	-- Parse the obtained string with cs2d formatting
	value, parsedvalue = self:ParseText(value)

	-- Calculate height position of the line
	local height = (#self.elements - 1) * (fontheight + self.padding)

	-- Calculate total wideness of the line
	local width = self.font:getWidth(parsedvalue)

	-- Resize the max width to update the layout
	if width > maxwidth then
		maxwidth = width
	end
	-- Add the fixed, formatted text to the texthash
	self.texthash:add(value, 0, height + self.padding/2)
	self:RedoLayout()

	local scrollbar = self.verticalbody:GetScrollBar()
	if scrollbar then
		scrollbar:ScrollBottom()
	end
end
--[[---------------------------------------------------------
	- func: SetFont
	- desc: set the object's font
--]]---------------------------------------------------------
function newobject:SetFont(font)
	self.texthash:setFont(font)
	self.font = font
	self:ParseElements()
	return self
end

function newobject:GetFont()
	local font = self.font
	return font
end

function newobject:SetPadding(padding)
	self.padding = padding
	self:ParseElements()
	return self
end

function newobject:GetPadding()
	local padding = self.padding
	return padding
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

---------- module end ----------
end
