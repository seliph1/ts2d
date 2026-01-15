--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- textinput object
local newobject = loveframes.NewObject("input", "loveframes_object_input", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	self.type = "input"
	self.width = 200
	self.height = 25
	self.offsetx = 0
	self.offsety = 0

	self.internals = {}
	self.cursor = loveframes.cursors.ibeam
	self.showindicator = true
	self.focus = false
	self.vbar = false
	self.hbar = false
    self.color = {1,1,1,1}
    self.highlightcolor = {1,1,1,1}
    self.cursorcolor = {1,1,1,1}
    self.shadow = true

	self.OnEnter = nil
	self.OnKeyPressed = nil
	self.OnControlKeyPressed = nil
	self.OnTextChanged = nil
	self.OnCopy = nil
	self.OnPaste = nil
	self:SetDrawFunc()

	-- Font properties
	local skin = loveframes.GetActiveSkin()
	local font = skin.directives.text_default_font

	self.font = font or loveframes.basicfont
	self.verticalpadding = 4
	self.horizontalpadding = 4

	-- Initialize the text input object
	self.field = loveframes.input()
	self.field:setType("normal")
	self.field:setFont(font)
	self.field:setDimensions(self.width, self.height)
    self.field:setCharacterLimit(30)
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function newobject:update(dt)
	if loveframes.inputobject == self and not self.visible then
		loveframes.inputobject = false
	end
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	-- check to see if the object is being hovered over
	self:CheckHover()

	-- move to parent if there is a parent
	if self.parent ~= loveframes.base then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end
	if loveframes.inputobject ~= self then return end

    self.field:update(dt)
	-- Update the callback update function
    local update = self.Update
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
	local x = math.floor(self.x)
	local y = math.floor(self.y)
	local width = self.width
	local height = self.height
    local field = self.field
    local shadow = self.shadow
   	local vpadding = self.verticalpadding
	local hpadding = self.horizontalpadding
    local color = self.color
	local highlightcolor = self.highlightcolor
	local cursorcolor = self.cursorcolor
    local font = self:GetFont()
	local font_height = font:getHeight()
	local blink_phase = field:getBlinkPhase()

	-- set the object's draw order
	self:SetDrawOrder()
	local ox, oy, ow, oh = love.graphics.getScissor()
    love.graphics.intersectScissor(x, y, width, height)

	local drawfunc = self.Draw or self.drawfunc
	if drawfunc then
		drawfunc(self)
	end

    love.graphics.setFont(font)
	-- Draw text
	for _, text, line_x, line_y in field:eachVisibleLine() do
		if line_y >= -font_height and line_y <= height + font_height then
			if shadow then
				love.graphics.setColor(0,0,0,1)
				love.graphics.print(text, x + hpadding + line_x + 1, y + vpadding + line_y + 1)
			end
			love.graphics.setColor(color)
			love.graphics.print(text, x + hpadding + line_x, y + vpadding + line_y)
		end
	end

   	-- Draw cursor blinking
	if (blink_phase/ 0.90) % 1 < .5 then
		local cursor_x, cursor_y, cursor_height = field:getCursorLayout()
		if cursor_x >= 0 and cursor_x <= width and cursor_y >= -font_height and cursor_y <= height + font_height then
			if shadow then
				love.graphics.setColor(0,0,0,1)
				love.graphics.rectangle("fill", cursor_x + x + hpadding + 1, cursor_y + y + vpadding + 1, 1, cursor_height)
			end
			love.graphics.setColor(cursorcolor)
			love.graphics.rectangle("fill", cursor_x + x + hpadding, cursor_y + y + vpadding, 1, cursor_height)

		end
	end

	-- Draw the selected text
	love.graphics.setColor(highlightcolor)
	for _, selection_x, selection_y, selection_w, selection_h in field:eachSelection() do
		if selection_y >= -font_height and selection_y + selection_h <= height + font_height then
			love.graphics.rectangle("fill", selection_x + x + hpadding, selection_y + y + vpadding, selection_w, selection_h)
		end
	end

    -- Draw the scroll bar
	local hOffset, hCoverage = field:getScrollHandles()
	local hHandleLength = hCoverage * width
	local hHandlePos    = hOffset   * width
	if hHandleLength < width then
		love.graphics.setColor(color)
		love.graphics.rectangle("fill", x+hHandlePos, y+height-2, hHandleLength, 2)
	end
    love.graphics.setScissor(ox, oy, ow, oh)

	local drawoverfunc = self.DrawOver or self.drawoverfunc
	if drawoverfunc then
		drawoverfunc(self)
	end
end

--[[---------------------------------------------------------
	- func: wheelmoved(x, y)
	- desc: called when the player moves a mouse wheel
--]]---------------------------------------------------------
function newobject:wheelmoved(x, y)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	if loveframes.inputobject ~= self then return end

    self.field:wheelmoved(x, y)
end
--[[---------------------------------------------------------
	- func: mousemoved(x, y, button)
	- desc: called when the player moves mouse
--]]---------------------------------------------------------
function newobject:mousemoved(x, y)
    if not self:OnState() then return end
	if not self:isUpdating() then return end
	if loveframes.inputobject ~= self then return end

	self.field:mousemoved(x - self.x, y - self.y)
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button) mousereleased(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button, istouch, presses)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	if loveframes.hoverobject == self then
		loveframes.inputobject = self
	end
	if loveframes.inputobject ~= self then return end
    self.field:mousepressed(x - self.x, y - self.y, button, presses)
end

function newobject:mousereleased(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	if loveframes.inputobject ~= self then return end

	self.field:mousereleased(x - self.x, y - self.y, button)
end

--[[---------------------------------------------------------
	- func: keypressed(key, isrepeat) keyreleased(key, isrepeat)
	- desc: called when the player presses a key
--]]---------------------------------------------------------
function newobject:keypressed(key, isrepeat)
	if not self:OnState() then return end
	if self.OnControlKeyPressed then
		self.OnControlKeyPressed(self, key)
	end
	if not self:isUpdating() then return end
	if key == "return" and self.OnEnter then
		self.OnEnter(self, self.field:getText())
		return
	end

	if loveframes.inputobject ~= self then return end
	self.field:keypressed(key, isrepeat)
	local oncopy = self.OnCopy
	local onpaste = self.OnPaste
	local oncut = self.OnCut

	if loveframes.IsCtrlDown() then
		if key == "c" then
			if oncopy then
				oncopy(self, love.system.getClipboardText())
			end
		elseif key == "x" then
			if oncut then
				oncut(self, love.system.getClipboardText())
			end
		elseif key == "v" then
			if onpaste then
				onpaste(self, love.system.getClipboardText())
			end
		end
	end


end

function newobject:keyreleased(key, isrepeat)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	if loveframes.inputobject ~= self then return end
end

--[[---------------------------------------------------------
	- func: textinput(text)
	- desc: called when the user inputs text
--]]---------------------------------------------------------
function newobject:textinput(text)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	if loveframes.inputobject ~= self then return end

	local ontextchanged = self.OnTextChanged
	local event, textedited = self.field:textinput(text)
	if event and textedited then
		if ontextchanged then
			ontextchanged(self, text)
		end
	end
end
--[[---------------------------------------------------------
	- func: SetFont(font)GetFont()
	- desc: sets/gets the object's font
--]]---------------------------------------------------------
function newobject:SetFont(font)
	self.font = font
	self.field:setFont(font)
	return self
end

function newobject:GetFont()
	return self.font
end

--[[---------------------------------------------------------
	- func: RedoLayout
	- desc: refresh the object layout
--]]---------------------------------------------------------
function newobject:RedoLayout()
	local x = self.width
	local y = self.height
	local hpadding = self.horizontalpadding
	local vpadding = self.verticalpadding
	self.field:resetBlinking()
	self.field:setDimensions(x - hpadding, y - vpadding)
end

--[[---------------------------------------------------------
	- func: SetPadding() SetHorizontalPadding() SetVerticalPadding()
	- desc: sets the object's padding
--]]---------------------------------------------------------
function newobject:SetPadding(padding)
	self.verticalpadding = padding
	self.horizontalpadding = padding

	self.field:setDimensions(self.width - math.max(padding*2, 0), self.height - math.max(padding*2, 0))
	return self
end

function newobject:SetVerticalPadding(padding)
	self.verticalpadding = padding
	self.field:setHeight(self.height - math.max(padding*2, 0))
	return self
end

function newobject:SetHorizontalPadding(padding)
	self.horizontalpadding = padding
	self.field:setWidth(self.width - math.max(padding*2, 0))
	return self
end
--[[---------------------------------------------------------
	- func: GetPadding() GetVerticalPadding() GetHorizontalPadding()
	- desc: gets the object's padding
--]]---------------------------------------------------------
function newobject:GetPadding()
	return self.verticalpadding, self.horizontalpadding
end

function newobject:GetVerticalPadding()
	return self.verticalpadding
end

function newobject:GetHorizontalPadding()
	return self.horizontalpadding
end

--[[---------------------------------------------------------
	- func: Clear()
	- desc: clears the object's text
--]]---------------------------------------------------------
function newobject:Clear()
	self.field:reset()
end

--[[---------------------------------------------------------
	- func: SetText(text)
	- desc: sets the object's text
--]]---------------------------------------------------------
function newobject:SetText(text)
	self.field:setText(text)
	return self
end

--[[---------------------------------------------------------
	- func: SetMultiline(text)
	- desc: sets the object's multiline functionality
--]]---------------------------------------------------------
function newobject:SetMultiline(bool)
	--self.field:setText(bool)
	self.multiline = bool
	if self.multiline then
		self.field:setType("multinowrap")
	else
		self.field:setType("normal")
	end
	return self
end
--[[---------------------------------------------------------
	- func: SetType(text)
	- desc: sets the object's input type property
--]]---------------------------------------------------------
---@param mode "multiwrap"|"multinowrap"|"password"|"normal"
function newobject:SetType(mode)
	if mode == "multiwrap" or mode == "multinowrap" then
		self.multiline = true
		self.field:setType(mode)
	else
		self.multiline = false
		self.field:setType(mode)
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetPasswordCharacter(text)
	- desc: sets the object's password character to display
--]]---------------------------------------------------------
function newobject:SetPasswordCharacter(character)
	self.field:setPasswordCharacter(character)
	return self
end

--[[---------------------------------------------------------
	- func: SetUsable(table)
	- desc: sets the object's allowed characters
--]]---------------------------------------------------------
function newobject:SetUsable(tbl)
	local filterFunction = function(input)
		--print(input, type(input))
		local filter = tbl
		for k,v in pairs(filter) do
			print(k, v, input)
			if v == input then
				return false
			end
		end
		return true
	end

	self.field:setFilter(filterFunction)
	return self
end
--[[---------------------------------------------------------
	- func: SetUnusable(table)
	- desc: sets the object's forbidden characters
--]]---------------------------------------------------------
function newobject:SetUnusable(tbl)
	local filterFunction = function(input)
		--print(input, type(input))
		local filter = tbl
		for k,v in pairs(filter) do
			print(k, v, input)
			if v == input then
				return true
			end
		end
		return false
	end

	self.field:setFilter(filterFunction)
	return self
end

--[[---------------------------------------------------------
	- func: SetCharacterLimit(table)
	- desc: sets the object's forbidden characters
--]]---------------------------------------------------------
function newobject:SetCharacterLimit(limit)
	self.field:setCharacterLimit(limit)
	return self
end

--[[---------------------------------------------------------
	- func: SetPlaceholderText(text) GetPLaceholderText()
	- desc: sets the object's default text to display
--]]---------------------------------------------------------
function newobject:SetPlaceholderText(text)
	self.field:setPlaceholderText(text)
	return self
end

function newobject:GetPlaceholderText()
	return self.field:GetPlaceholderText()
end

--[[---------------------------------------------------------
	- func: EnableInput, GetInputStatus
	- desc: sets/gets the object's input status
--]]---------------------------------------------------------
function newobject:EnableInput(bool)
	if bool then
		loveframes.inputobject = self
		self.field:resetBlinking()
	else
		loveframes.inputobject = nil
	end
end
--[[---------------------------------------------------------
	- func: GetText()
	- desc: gets the object's text
--]]---------------------------------------------------------
function newobject:GetText()
	return self.field:getText()
end

--[[---------------------------------------------------------
	- func: GetColor() SetColor()
	- desc: gets the object's color
--]]---------------------------------------------------------
function newobject:GetColor()
	return self.color
end

function newobject:SetColor(r,g,b,a)
    self.color[1] = r or self.color[1]
    self.color[2] = g or self.color[2]
    self.color[3] = b or self.color[3]
    self.color[4] = a or self.color[4]
	return self
end

function newobject:GetHighlightColor()
	return self.highlightcolor
end

function newobject:SetHighlightColor(r,g,b,a)
    self.highlightcolor[1] = r or self.highlightcolor[1]
    self.highlightcolor[2] = g or self.highlightcolor[2]
    self.highlightcolor[3] = b or self.highlightcolor[3]
    self.highlightcolor[4] = a or self.highlightcolor[4]
	return self
end

function newobject:GetCursorColor()
	return self.cursorcolor
end

function newobject:SetCursorColor(r,g,b,a)
    self.cursorcolor[1] = r or self.cursorcolor[1]
    self.cursorcolor[2] = g or self.cursorcolor[2]
    self.cursorcolor[3] = b or self.cursorcolor[3]
    self.cursorcolor[4] = a or self.cursorcolor[4]
	return self
end
--[[---------------------------------------------------------
	- func: SetShadow(bool) GetShadow(bool)
	- desc: sets the object's shadow
--]]---------------------------------------------------------
function newobject:SetShadow(bool)
    self.shadow = bool
	return self
end
function newobject:GetShadow(bool)
    return self.shadow
end
--[[---------------------------------------------------------
	- func: SetVisible(bool)
	- desc: sets the object's visibility
--]]---------------------------------------------------------
function newobject:SetVisible(bool)
	self.visible = bool
	self.field:resetBlinking()
	return self
end

function newobject:SetMaxHistory(size)
	self.field:setMaxHistory(size)
	return self
end

---------- module end ----------
end
