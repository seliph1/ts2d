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
    self.internals = {}
	self.elements = {}
	self.padding = 5
	self.selected = 0
	self.hovered = 0
	self.spacing = 0
	self.background = nil
	self.font = font
	self.texthash = love.graphics.newTextBatch(font)
	self.defaultcolor = color or {1,1,1,1}
	self.cursor = loveframes.cursors.ibeam
	self.lastheight = 0

	local verticalbody = loveframes.objects["scrollbody"]:new(self, "vertical")
	table.insert(self.internals, verticalbody)
	self.verticalbody = verticalbody

	self.itemwidth = self.width
	self.itemheight = self.height
    self.extraheight = 0
    self.extrawidth = 0
	self.offsetx = 0
	self.offsety = 0
	self.buttonscrollamount = 1
	self.mousewheelscrollamount = 1

	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the element
--]]---------------------------------------------------------
function newobject:update(dt)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
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
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local x = self.x
	local y = self.y
	local width = self.width
	local height = self.height
	local drawfunc = self.Draw or self.drawfunc
	local drawoverfunc = self.DrawOver or self.drawoverfunc
	local internals = self.internals
	
	local ox, oy, ow, oh = love.graphics.getScissor()
	love.graphics.intersectScissor(x, y, width, height)
	if drawfunc then
		drawfunc(self)
	end
	love.graphics.setScissor(ox, oy, ow, oh)
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
	if not self:OnState() then return end
	if not self:isUpdating() then return end
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
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	for _, v in ipairs(self.internals) do
		v:mousereleased(x, y, button)
	end
end
--[[---------------------------------------------------------
	- func: wheelmoved(x, y)
	- desc: called when the player moves a mouse wheel
--]]---------------------------------------------------------
function newobject:wheelmoved(x, y)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	if not self.hover then return end
	for _, v in ipairs(self.internals) do
		v:wheelmoved(x, y)
	end
end
--[[---------------------------------------------------------
	- func: RedoLayout()
	- desc: redo the layout of the scrollpanel
--]]---------------------------------------------------------
function newobject:RedoLayout()
	local elements = self.elements
	local fontheight = self.font:getHeight()

    self.itemwidth = self.width
    self.itemheight = self.lastheight
    self.extraheight = self.itemheight - self.height
    self.extrawidth = self.itemwidth - self.width
end

--[[---------------------------------------------------------
	- func: AddElement()
	- desc: add an element into the list
--]]---------------------------------------------------------
function newobject:AddElement(item, append)
	local append = append or true
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

	local last = 1
	while true do
		local i, j = str:find("©", last)
		if not i then
			-- restante
			table.insert(formattedchunks, defaultColor)
			table.insert(formattedchunks, str:sub(last))
			table.insert(formattedstring, str:sub(last))
			break
		end

		-- trecho antes do ©
		if i > last then
			local segment = str:sub(last, i-1)
			table.insert(formattedchunks, defaultColor)
			table.insert(formattedchunks, segment)
			table.insert(formattedstring, segment)
		end

		-- agora pega o próximo trecho até o próximo © ou fim
		local k = str:find("©", j+1) or (#str+1)
		local capture = str:sub(j+1, k-1)

		local r,g,b = capture:match("(%d%d%d)(%d%d%d)(%d%d%d)")
		local text = capture:sub(10)
		if r and g and b then
			table.insert(formattedchunks, {tonumber(r)/255, tonumber(g)/255, tonumber(b)/255})
			table.insert(formattedchunks, text)
			table.insert(formattedstring, text)
		else
			-- não é cor válida, volta o texto inteiro
			local bad = "©"..capture
			local previousColor
			if #formattedchunks > 0 then
				previousColor = formattedchunks[#formattedchunks-2]
			else
				previousColor = defaultColor
			end
			table.insert(formattedchunks, previousColor)
			table.insert(formattedchunks, bad)
			table.insert(formattedstring, bad)
		end
		last = k
	end

	return formattedchunks, table.concat(formattedstring)
end

function newobject:ParseElements()
	self.texthash:clear()
	self.lastheight = 0
	local elements = self.elements
	for _, value in ipairs(elements) do
		local lastheight = self.lastheight
		local parsedvalue = ""
		-- Fix the text
		value = self:fixUTF8(value," ")

		-- Parse the obtained string with cs2d formatting
		value, parsedvalue = self:ParseText(value)

		-- Adds the offset from vertical body if applicable
		local truewidth = self.width
		if self.verticalbody then
			truewidth = self.width - self.verticalbody:GetWidth()
		end

		-- Add the fixed, formatted text to the texthash object
		local index
		local status, err = pcall(
			self.texthash.addf,
			self.texthash,
			value,
			truewidth,
			"left",
			0,
			lastheight
		)
		if not status then
			index = self.texthash:addf(tostring(err), self.width - self.verticalbody:GetWidth(), "left", 0, lastheight)
		else
			index = err
		end

		-- Get the total height spanned by that line
		local addedheight = self.texthash:getHeight(index)

		-- Increment the height property
		self.lastheight = self.lastheight + addedheight
	end
	self:RedoLayout()

	if self.verticalbody then
		self.verticalbody:ScrollBottom()
	else
		self.offsety = self.itemheight - self.height
	end
end

function newobject:AppendElement(value)
	local lastheight = self.lastheight
	local parsedvalue = ""
	-- Fix the text
	value = self:fixUTF8(value, " ")

	-- Parse the obtained string with cs2d formatting
	value, parsedvalue = self:ParseText(value)

	-- Adds the offset from vertical body if applicable
	local truewidth = self.width
	if self.verticalbody then
		truewidth = self.width - self.verticalbody:GetWidth()
	end

	-- Add the fixed, formatted text to the texthash object
	--local index = self.texthash:addf(value, self.width - self.verticalbody:GetWidth(), "left", 0, lastheight)
	local index
	local status, err = pcall(
		self.texthash.addf,
		self.texthash,
		value,
		truewidth,
		"left",
		0,
		lastheight
	)
	if not status then
		index = self.texthash:addf(tostring(err), self.width - self.verticalbody:GetWidth(), "left", 0, lastheight)
	else
		index = err
	end

	-- Get the total height spanned by that line
	local addedheight = self.texthash:getHeight(index)

	-- Increment the height property
	self.lastheight = self.lastheight + addedheight
	self:RedoLayout()

	if self.verticalbody then
		self.verticalbody:ScrollBottom()
	else
		self.offsety = self.itemheight - self.height
	end
end
--[[---------------------------------------------------------
	- func: Clear()
	- desc: clear this object of all data
--]]---------------------------------------------------------
function newobject:Clear()
	self.text = ""
	self.texthash:clear()
	self.elements = {}
	self.lastheight = 0
	self.itemwidth = self.width
    self.itemheight = 0
    self.extraheight = 0
    self.extrawidth = 0
	self.offsetx = 0
	self.offsety = 0

	local scrollbar = self.verticalbody:GetScrollBar()
	if scrollbar then
		scrollbar:ScrollTop()
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
	- func: SetScrollBody
	- desc: removes/adds a scroll body
--]]---------------------------------------------------------

function newobject:SetScrollBody(bool)
	if bool then
		if (not self.verticalbody) then
			local verticalbody = loveframes.objects["scrollbody"]:new(self, "vertical")
			table.insert(self.internals, verticalbody)
			self.verticalbody = verticalbody
		end
	else
		self.verticalbody:Remove()
		self.verticalbody = nil
	end
	self:ParseElements()
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

---------- module end ----------
end
