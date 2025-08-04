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


	-- Initialize the text input object
	self.field = loveframes.InputField()
	self.field:setType("multinowrap")
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
	-- check to see if the object is being hovered over
	self:CheckHover()
	local hover = self.hover
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update
	local inputobject = loveframes.inputobject
	local internals = self.internals
	-- move to parent if there is a parent
	if parent ~= base then
		local parentx = parent.x
		local parenty = parent.y
		local staticx = self.staticx
		local staticy = self.staticy
		self.x = parentx + staticx
		self.y = parenty + staticy
	end
	-- Deselect text if the object isn't active
	if inputobject ~= self then
		self.focus = false
	end

	self.itemwidth = self.field:getTextWidth()
	self.itemheight = self.field:getTextHeight()
	self.extrawidth = self.itemwidth - self.width
	self.extraheight = self.itemheight - self.height
	
	if self.itemheight > self.height then
		if not self.vbar then
			local scrollbody = loveframes.objects["scrollbody"]:new(self, "vertical")
			--scrollbody.internals[1].internals[1].autoscroll = false
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
	-- set the object's draw order
	self:SetDrawOrder()
	-- Set the stencil function to cut out the stuff
	local stencilfunc = function() love.graphics.rectangle("fill", x, y, width, height) end
	if self.vbar and self.hbar then
		stencilfunc = function() love.graphics.rectangle("fill", x, y, width - 16, height - 16) end
	end
	-- Begin of stencil
	--love.graphics.stencil(stencilfunc)
	--love.graphics.setStencilTest("greater", 0)
	local drawfunc = self.Draw or self.drawfunc
	if drawfunc then
		drawfunc(self)
	end

	local internals = self.internals
	if internals then
		for k, v in ipairs(internals) do
			v:draw()
		end
	end
	local drawoverfunc = self.DrawOver or self.drawoverfunc
	if drawoverfunc then
		drawfunc(self)
	end

	-- End of stencil
	--love.graphics.setStencilTest()
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
end

--[[---------------------------------------------------------
	- func: mousemoved(x, y, button)
	- desc: called when the player moves mouse
--]]---------------------------------------------------------
function newobject:mousemoved(x, y)
	self.field:mousemoved(x - self.x, y - self.y)
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button, istouch, presses)
	local state = loveframes.state
	local selfstate = self.state
	if state ~= selfstate then
		return
	end
	local visible = self.visible
	if not visible then
		return
	end
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
	end
	for k, v in ipairs(internals) do
		v:mousepressed(x, y, button)
	end
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
	local visible = self.visible
	if not visible then
		return
	end

	self.field:mousereleased(x - self.x, y - self.y, button)
	local internals = self.internals
	for k, v in ipairs(internals) do
		v:mousereleased(x, y, button)
	end
end

--[[---------------------------------------------------------
	- func: keypressed(key, isrepeat)
	- desc: called when the player presses a key
--]]---------------------------------------------------------
function newobject:keypressed(key, isrepeat)
	local state = loveframes.state
	local selfstate = self.state
	if state ~= selfstate then
		return
	end
	local focus = self.focus
	local visible = self.visible
	if not (visible or focus) then
		return
	end
	local inputobject = loveframes.inputobject
	if inputobject == self then
		self.field:keypressed(key, isrepeat)
	end
end

--[[---------------------------------------------------------
	- func: keyreleased(key)
	- desc: called when the player releases a key
--]]---------------------------------------------------------
function newobject:keyreleased(key, isrepeat)
	local state = loveframes.state
	local selfstate = self.state
	if state ~= selfstate then
		return
	end
	local focus = self.focus
	local visible = self.visible
	if not (visible or focus) then
		return
	end
	local inputobject = loveframes.inputobject
	if inputobject == self then
		--self.field:keyreleased(key, isrepeat)
	end
end

--[[---------------------------------------------------------
	- func: textinput(text)
	- desc: called when the inputs text
--]]---------------------------------------------------------
function newobject:textinput(text)
	local inputobject = loveframes.inputobject
	if inputobject == self then
		self.field:textinput(text)
	end
end
--[[---------------------------------------------------------
	- func: SetFont(font)
	- desc: sets the object's font
--]]---------------------------------------------------------
function newobject:SetFont(font)
	self.font = font
	return self
end
--[[---------------------------------------------------------
	- func: GetFont()
	- desc: gets the object's font
--]]---------------------------------------------------------
function newobject:GetFont()
	return self.font
end

--[[---------------------------------------------------------
	- func: SetSize(font)
	- desc: sets the object's size
--]]---------------------------------------------------------
function newobject:SetSize(x, y)
	self.width = x
	self.height = y
	self.field:setDimensions(x, y)
	return self
end
--[[---------------------------------------------------------
	- func: GetSize()
	- desc: gets the object's size
--]]---------------------------------------------------------
function newobject:GetSize()
	return self.width, self.height
end
--[[---------------------------------------------------------
	- func: SetFocus(focus)
	- desc: sets the object's focus
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

--[[---------------------------------------------------------
	- func: GetFocus()
	- desc: gets the object's focus
--]]---------------------------------------------------------
function newobject:GetFocus()
	return self.focus
end

--[[---------------------------------------------------------
	- func: Clear()
	- desc: clears the object's text
--]]---------------------------------------------------------
function newobject:Clear()
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
	- func: GetText()
	- desc: gets the object's text
--]]---------------------------------------------------------
function newobject:GetText()
	return self.text
end

--[[---------------------------------------------------------
	- func: SetVisible(bool)
	- desc: sets the object's visibility
--]]---------------------------------------------------------
function newobject:SetVisible(bool)
	self.visible = bool
	return self
end

---------- module end ----------
end
