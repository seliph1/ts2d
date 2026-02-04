--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- textinput object
local TextBox = loveframes.NewObject("textbox", "loveframes_object_textbox", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function TextBox:initialize()
	self.type = "textbox"
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

	self.itemwidth = 0
	self.itemheight = 0
	self.extrawidth = 0
	self.extraheight = 0
	self.buttonscrollamount = 1
	self.mousewheelscrollamount = 1
	self.autoscroll = true

	self.OnEnter = nil
	self.OnKeyPressed = nil
	self.OnControlKeyPressed = nil
	self.OnTextChanged = nil
	self.OnFocusGained = nil
	self.OnFocusLost = nil
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
end

--[[---------------------------------------------------------
	- func: GetVerticalScrollBody()
	- desc: gets the object's vertical scroll body
--]]---------------------------------------------------------
function TextBox:GetVerticalScrollBody()
	local vbar = self.vbar
	local internals = self.internals
	local item = false
	if vbar then
		for k, v in ipairs(internals) do
			if v.type == "scrollbody" and v.bartype == "vertical" then
				item = v
			end
		end
	end
	return item
end


--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function TextBox:update(dt)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	-- check to see if the object is being hovered over
	self:CheckHover()

	local parent = self.parent
	local update = self.Update
	local internals = self.internals
	local base = loveframes.base
	local inputobject = loveframes.inputobject
	-- move to parent if there is a parent

	if parent ~= base then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end

	-- Deselect text if the object isn't active
	if inputobject ~= self then
		self.focus = false
		return
	end

	self.itemwidth = self.field:getTextWidth() + self.horizontalpadding
	self.itemheight = self.field:getTextHeight() + self.verticalpadding

	self.extrawidth = math.max(0, self.itemwidth - self.width)
	self.extraheight = math.max(0, self.itemheight - self.height)

	local fieldtype = self.field:getType()
	if self.itemheight > self.height and fieldtype ~= "normal" and fieldtype ~= "password"  then
		if not self.vbar then
			local scrollbody = loveframes.objects["scrollbody"]:new(self, "vertical")
			table.insert(self.internals, scrollbody)
			self.vbar = true
		end
	else
		if self.vbar then
			local scrollbody = self:GetVerticalScrollBody()
			if scrollbody then
				scrollbody:Remove()
			end
			self.vbar = false
			self.offsety = 0
		end
	end

	local scrollbody = self:GetVerticalScrollBody()
	if scrollbody then
		if scrollbody:IsDragging() then
			self.field:setScroll(self.offsetx, self.offsety)
		end
	end

	-- Update children
	for k, v in ipairs(internals) do
		v:update(dt)
	end
	-- Update the callback update function
	if update then
		update(self, dt)
	end
end

--[[---------------------------------------------------------
	- func: draw()
	- desc: draws the object
--]]---------------------------------------------------------
function TextBox:draw()
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local x = self.x
	local y = self.y
	local width = self.width
	local height = self.height
	-- set the object's draw order
	self:SetDrawOrder()
	local ox, oy, ow, oh = love.graphics.getScissor()
	local drawfunc = self.Draw or self.drawfunc

	love.graphics.intersectScissor(x, y, width, height)
	if drawfunc then
		drawfunc(self)
	end
	love.graphics.setScissor(ox, oy, ow, oh)

	local internals = self.internals
	if internals then
		for k, v in ipairs(internals) do
			v:draw()
		end
	end

	local drawoverfunc = self.DrawOver or self.drawoverfunc
	if drawoverfunc then
		drawoverfunc(self)
	end
end

--[[---------------------------------------------------------
	- func: wheelmoved(x, y)
	- desc: called when the player moves a mouse wheel
--]]---------------------------------------------------------
function TextBox:wheelmoved(x, y)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	--self.field:wheelmoved(x, y)

	--[[
	local scrollbody = self:GetVerticalScrollBody()
	if scrollbody then
		local dx, dy = self.field:getScroll()
		scrollbody:ScrollTo(dy/self.itemheight)
	end]]
end
--[[---------------------------------------------------------
	- func: mousemoved(x, y, button)
	- desc: called when the player moves mouse
--]]---------------------------------------------------------
function TextBox:mousemoved(x, y)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	if self.hover then
		self.field:mousemoved(x - self.x, y - self.y)
	end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button) mousereleased(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function TextBox:mousepressed(x, y, button, istouch, presses)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	local hover = self.hover
	local inputobject = loveframes.inputobject
	local onfocusgained = self.OnFocusGained
	local onfocuslost = self.OnFocusLost
	local focus = self.focus
	local internals = self.internals

	-- Check if it's hovering the object
	if hover then
		-- Call the callback of focus 
		if onfocusgained and not focus then
			onfocusgained(self)
		end
		-- Change focus status to true
		self.focus = true
		-- Change input target to the object focused
		if button == 1 then
			loveframes.inputobject = self
		end
		self.field:mousepressed(x - self.x, y - self.y, button, presses)
	else
		-- Defocus on any button press outside the widget area
		if inputobject == self then
			loveframes.inputobject = false
			-- Call the callback
			if onfocuslost then
				onfocuslost(self)
			end
			-- Change focus status to false
			self.focus = false
		end
	end

	for k, v in ipairs(internals) do
		v:mousepressed(x, y, button)
	end
end


function TextBox:mousereleased(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	self.field:mousereleased(x - self.x, y - self.y, button)
end

--[[---------------------------------------------------------
	- func: keypressed(key, isrepeat) keyreleased(key, isrepeat)
	- desc: called when the player presses a key
--]]---------------------------------------------------------
function TextBox:keypressed(key, isrepeat)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	if self.OnControlKeyPressed then
		self.OnControlKeyPressed(self, key)
	end
	if key == "return" then
		if self.OnEnter then
			self.OnEnter(self, self.field:getText())
		end
	end

	if loveframes.inputobject ~= self then return end
	self.field:keypressed(key, isrepeat)
	local focus = self.focus
	local oncopy = self.OnCopy
	local onpaste = self.OnPaste
	local oncut = self.OnCut

	if loveframes.IsCtrlDown() and focus then
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

function TextBox:keyreleased(key, isrepeat)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	if loveframes.inputobject ~= self then return end
end

--[[---------------------------------------------------------
	- func: textinput(text)
	- desc: called when the user inputs text
--]]---------------------------------------------------------
function TextBox:textinput(text)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	if loveframes.inputobject ~= self then return end

	local ontextchanged = self.OnTextChanged
	local event, textedited = self.field:textinput(text)
	if event and textedited  then
		if ontextchanged then
			ontextchanged(self, text)
		end

		--[[
		if self.autoscroll then
			local scrollbody = self:GetVerticalScrollBody()
			if scrollbody then
				scrollbody:ScrollBottom()
			end
		end]]
	end
end
--[[---------------------------------------------------------
	- func: SetFont(font)GetFont()
	- desc: sets/gets the object's font
--]]---------------------------------------------------------
function TextBox:SetFont(font)
	self.font = font
	self.field:setFont(font)
	return self
end

function TextBox:GetFont()
	return self.font
end

--[[---------------------------------------------------------
	- func: RedoLayout
	- desc: refresh the object layout
--]]---------------------------------------------------------
function TextBox:RedoLayout()
	local x = self.width
	local y = self.height
	local hpadding = self.horizontalpadding
	local vpadding = self.verticalpadding
	self.field:setDimensions(x - hpadding, y - vpadding)
	self.field:resetBlinking()
end

--[[---------------------------------------------------------
	- func: SetPadding() SetHorizontalPadding() SetVerticalPadding()
	- desc: sets the object's padding
--]]---------------------------------------------------------
function TextBox:SetPadding(padding)
	self.verticalpadding = padding
	self.horizontalpadding = padding

	self.field:setDimensions(self.width - math.max(padding*2, 0), self.height - math.max(padding*2, 0))
	return self
end

function TextBox:SetVerticalPadding(padding)
	self.verticalpadding = padding
	self.field:setHeight(self.height - math.max(padding*2, 0))
	return self
end

function TextBox:SetHorizontalPadding(padding)
	self.horizontalpadding = padding
	self.field:setWidth(self.width - math.max(padding*2, 0))
	return self
end
--[[---------------------------------------------------------
	- func: GetPadding() GetVerticalPadding() GetHorizontalPadding()
	- desc: gets the object's padding
--]]---------------------------------------------------------
function TextBox:GetPadding()
	return self.verticalpadding, self.horizontalpadding
end

function TextBox:GetVerticalPadding()
	return self.verticalpadding
end

function TextBox:GetHorizontalPadding()
	return self.horizontalpadding
end
--[[---------------------------------------------------------
	- func: SetFocus(focus) GetFocus()
	- desc: sets/gets the object's focus
--]]---------------------------------------------------------
function TextBox:SetFocus(focus)
	local inputobject = loveframes.inputobject
	local onfocusgained = self.OnFocusGained
	local onfocuslost = self.OnFocusLost
	self.focus = focus
	if focus then
		loveframes.inputobject = self
		self.field:resetBlinking()
		if onfocusgained then
			onfocusgained(self)
		end
	else
		if inputobject == self then
			loveframes.inputobject = false
		end
		if onfocuslost then
			onfocuslost(self)
		end
	end
	return self
end

function TextBox:GetFocus()
	return self.focus
end

--[[---------------------------------------------------------
	- func: Clear()
	- desc: clears the object's text
--]]---------------------------------------------------------
function TextBox:Clear()
	self.field:reset()
end

--[[---------------------------------------------------------
	- func: Cut()/Copy()/Paste()
	- desc: common text input features
--]]---------------------------------------------------------
function TextBox:Cut()
	local text = ""
	local selectionStart, selectionEnd = self.field:getSelection()
	if selectionStart ~= selectionEnd then
		text = self.field:getSelectedVisibleText()
	else
		text = self.field:getText()
	end

	love.system.setClipboardText(text)
	if self.field.editingEnabled then
		if selectionStart == selectionEnd then
			self.field:setText("")
		else
			self.field:insert("")
		end
	else
		self.field:resetBlinking()
	end

	local oncut = self.OnCut
	if oncut then
		oncut(self, love.system.getClipboardText())
	end
end

function TextBox:Copy()
	local text = ""
	local selectionStart, selectionEnd = self.field:getSelection()
	if selectionStart ~= selectionEnd then
		text = self.field:getSelectedVisibleText()
	else
		text = self.field:getText()
	end
	if text == "" then return end

	love.system.setClipboardText(text)
	self.field:resetBlinking()

	local oncopy = self.OnCopy
	if oncopy then
		oncopy(self, love.system.getClipboardText())
	end
end

function TextBox:Paste()
	if not self.field.editingEnabled then return end
	local text = love.system.getClipboardText()
	local isMultiline = self.field:isMultiline()

	text = text:gsub((isMultiline and "[%z\1-\8\11-\31]+" or "[%z\1-\8\10-\31]+"), "") -- Should we allow horizontal tab?
	if text ~= "" then
		self.field:insert(text)
	end

	local onpaste = self.OnPaste
	if onpaste then
		onpaste(self, love.system.getClipboardText())
	end
end

--[[---------------------------------------------------------
	- func: SetText(text)
	- desc: sets the object's text
--]]---------------------------------------------------------
function TextBox:SetText(text)
	self.field:setText(text)
	return self
end

--[[---------------------------------------------------------
	- func: SetMultiline(text)
	- desc: sets the object's multiline functionality
--]]---------------------------------------------------------
function TextBox:SetMultiline(bool)
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
function TextBox:SetType(mode)
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
function TextBox:SetPasswordCharacter(character)
	self.field:setPasswordCharacter(character)
	return self
end

--[[---------------------------------------------------------
	- func: SetUsable(table)
	- desc: sets the object's allowed characters
--]]---------------------------------------------------------
function TextBox:SetUsable(tbl)
	local filterFunction = function(input)
		local filter = tbl
		for k,v in pairs(filter) do
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
function TextBox:SetUnusable(tbl)
	local filterFunction = function(input)
		local filter = tbl
		for k,v in pairs(filter) do
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
function TextBox:SetCharacterLimit(limit)
	self.field:setCharacterLimit(limit)
	return self
end

--[[---------------------------------------------------------
	- func: SetPlaceholderText(text) GetPLaceholderText()
	- desc: sets the object's default text to display
--]]---------------------------------------------------------
function TextBox:SetPlaceholderText(text)
	self.field:setPlaceholderText(text)
	return self
end

function TextBox:GetPlaceholderText()
	return self.field:GetPlaceholderText()
end

--[[---------------------------------------------------------
	- func: GetText()
	- desc: gets the object's text
--]]---------------------------------------------------------
function TextBox:GetText()
	return self.field:getText()
end

function TextBox:GetFieldObject()
	return self.field
end

function TextBox:MoveCursorTo(pos)
	if type(pos) == "number" then
		self.field:setCursor(pos)
	elseif type(pos) == "string" then
		if pos == "end" then
			self.field:setCursor(self.field:getTextLength())
		elseif pos == "start" then
			self.field:setCursor(0)
		end
	end
end

function TextBox:SetMaxHistory(size)
	self.field:setMaxHistory(size)
	return self
end


function TextBox:SetVisible(bool)
	self.visible = bool
	self.field:resetBlinking()
	return self
end
---------- module end ----------
end
