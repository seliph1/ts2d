--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- textinput object
local newobject = loveframes.NewObject("textbox", "loveframes_object_textbox", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
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
function newobject:GetVerticalScrollBody()
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
function newobject:update(dt)
	if not self:OnState() then return end
	if not self:IsVisible() then return end
	-- check to see if the object is being hovered over
	self:CheckHover()
	local hover = self.hover
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update
	local inputobject = loveframes.inputobject
	local internals = self.internals
	local fieldtype = self.field:getType()
	-- move to parent if there is a parent
	if parent ~= base then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end
	-- Deselect text if the object isn't active
	if inputobject ~= self then
		self.focus = false
	end

	self.itemwidth = self.field:getTextWidth()
	self.itemheight = self.field:getTextHeight()
	self.extrawidth = self.itemwidth - self.width
	self.extraheight = self.itemheight - self.height

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

	--[[
	local scrollbody = self:GetVerticalScrollBody()
	if scrollbody then
		local scrollbar = scrollbody:GetScrollBar()
		local position = scrollbar:GetBarAmount()

		if scrollbar:IsDragging() then
			self.field:setScroll(0, position * self.extraheight)
		end
		local upbutton, downbutton = scrollbody:GetScrollButtons()
		local area = scrollbody:GetScrollArea()

		if downbutton.down then
			self.field:scroll(0, self.buttonscrollamount * self.itemheight/scrollbody:GetScrollSize())
		end

		if upbutton.down then
			self.field:scroll(0, -self.buttonscrollamount * self.itemheight/scrollbody:GetScrollSize())
		end

		if area.down then
			self.field:setScroll(0, position * self.extraheight)
		end
	end]]
	local scrollbody = self:GetVerticalScrollBody()
	if scrollbody then
		--local scrollbar = scrollbody:GetScrollBar()
		--local x,y, h = self.field:getCursorLayout()
		--print(x, y, h)
		--scrollbar:ScrollTo(x)
	end

	self.field:setScroll(self.offsetx, self.offsety)



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
function newobject:draw()
	if not self:OnState() then return end
	if not self:IsVisible() then return end
	local x = self.x
	local y = self.y
	local width = self.width
	local height = self.height
	-- set the object's draw order
	self:SetDrawOrder()
	love.graphics.setScissor(x, y, width, height)
	local drawfunc = self.Draw or self.drawfunc
	if drawfunc then
		drawfunc(self)
	end
	love.graphics.setScissor()

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
function newobject:wheelmoved(x, y)
	if not self:OnState() then return end
	if not self:IsVisible() then return end
	local internals = self.internals
	if internals then
		for k, v in ipairs(internals) do
			v:wheelmoved(x, y)
		end
	end
end
--[[---------------------------------------------------------
	- func: mousemoved(x, y, button)
	- desc: called when the player moves mouse
--]]---------------------------------------------------------
function newobject:mousemoved(x, y)
	self.field:mousemoved(x - self.x, y - self.y)
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button) mousereleased(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button, istouch, presses)
	if not self:OnState() then return end
	if not self:IsVisible() then return end
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
			if inputobject ~= self then
				loveframes.inputobject = self
			end
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
		-- Deselect all text
		self.field:releaseMouse()
		self.field:selectNone()
	end
	for k, v in ipairs(internals) do
		v:mousepressed(x, y, button)
	end
end

function newobject:mousereleased(x, y, button)
	if not self:OnState() then return end
	if not self:IsVisible() then return end
	self.field:mousereleased(x - self.x, y - self.y, button)
	local internals = self.internals
	for k, v in ipairs(internals) do
		v:mousereleased(x, y, button)
	end
end

--[[---------------------------------------------------------
	- func: keypressed(key, isrepeat) keyreleased(key, isrepeat)
	- desc: called when the player presses a key
--]]---------------------------------------------------------
function newobject:keypressed(key, isrepeat)
	if not self:OnState() then return end
	if not self:IsVisible() then return end
	local focus = self.focus
	local inputobject = loveframes.inputobject
	if inputobject == self then
		self.field:keypressed(key, isrepeat)
	end

	if key == "return" then
		if self.OnEnter then
			self.OnEnter(self, self.field:getText())
		end
	end


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

	if self.OnControlKeyPressed then
		self.OnControlKeyPressed(self, key)
	end
end

function newobject:keyreleased(key, isrepeat)
	if not self:OnState() then return end
	if not self:IsVisible() then return end
	local inputobject = loveframes.inputobject
	if inputobject == self then
		--self.field:keyreleased(key, isrepeat)
	end
end

--[[---------------------------------------------------------
	- func: textinput(text)
	- desc: called when the user inputs text
--]]---------------------------------------------------------
function newobject:textinput(text)
	local inputobject = loveframes.inputobject
	local ontextchanged = self.OnTextChanged
	if inputobject == self then
		local event, textedited = self.field:textinput(text)
		if event and textedited and ontextchanged then
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
	- func: SetSize(x, y) SetWidth(x, y) SetHeight(x, y) GetSize()
	- desc: sets/gets the object's size
--]]---------------------------------------------------------
function newobject:SetSize(x, y)
	self.width = x
	self.height = y
	local hpadding = math.max(self.horizontalpadding*2, 0)
	local vpadding = math.max(self.verticalpadding*2, 0)
	self.field:setDimensions(x - hpadding, y - vpadding)
	return self
end

function newobject:SetWidth(x)
	self.width = x
	local padding = math.max(self.horizontalpadding*2, 0)
	self.field:setWidth(x - padding)
	return self
end

function newobject:SetHeight(y)
	self.height = y
	local padding = math.max(self.verticalpadding*2, 0)
	self.field:setHeight(y - padding)
	return self
end

function newobject:GetSize()
	return self.width, self.height
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
	- func: SetFocus(focus) GetFocus()
	- desc: sets/gets the object's focus
--]]---------------------------------------------------------
function newobject:SetFocus(focus)
	local inputobject = loveframes.inputobject
	local onfocusgained = self.OnFocusGained
	local onfocuslost = self.OnFocusLost
	self.focus = focus
	if focus then
		loveframes.inputobject = self
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

function newobject:GetFocus()
	return self.focus
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
	- func: GetText()
	- desc: gets the object's text
--]]---------------------------------------------------------
function newobject:GetText()
	return self.field:getText()
end

--[[---------------------------------------------------------
	- func: SetVisible(bool)
	- desc: sets the object's visibility
--]]---------------------------------------------------------
function newobject:SetVisible(bool)
	self.visible = bool
	return self
end

function newobject:SetMaxHistory(size)
	self.field:setMaxHistory(size)
	return self
end

---------- module end ----------
end
