--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	loveframes.lexers = loveframes.lexers or {}

	local lua_keywords = {
		["and"] = true,
		["break"] = true,
		["do"] = true,
		["else"] = true,
		["elseif"] = true,
		["end"] = true,
		["false"] = true,
		["for"] = true,
		["function"] = true,
		["if"] = true,
		["in"] = true,
		["local"] = true,
		["nil"] = true,
		["not"] = true,
		["or"] = true,
		["repeat"] = true,
		["return"] = true,
		["then"] = true,
		["true"] = true,
		["until"] = true,
		["while"] = true
	}

	loveframes.lexers.lua = function(text, cols)
		local out = {}
		local pos = 1
		local len = #text
		while pos <= len do
			local byte = string.byte(text, pos)
			local char_len = 1
			if byte >= 192 and byte <= 223 then
				char_len = 2
			elseif byte >= 224 and byte <= 239 then
				char_len = 3
			elseif byte >= 240 and byte <= 247 then
				char_len = 4
			end

			local c = text:sub(pos, pos + char_len - 1)

			if text:sub(pos, pos + 1) == "--" then
				table.insert(out, cols.comment)
				table.insert(out, text:sub(pos))
				break
			elseif c == '"' or c == "'" then
				local end_pos = text:find(c, pos + 1)
				if not end_pos then end_pos = len end
				local str_chunk = text:sub(pos, end_pos)
				table.insert(out, cols.string)
				table.insert(out, str_chunk)
				pos = end_pos + 1
			elseif c:match("%d") then
				local num_end = pos
				while num_end <= len and text:sub(num_end, num_end):match("[%d%.]") do
					num_end = num_end + 1
				end
				local num_chunk = text:sub(pos, num_end - 1)
				table.insert(out, cols.number)
				table.insert(out, num_chunk)
				pos = num_end
			elseif c:match("[%a_]") then
				local word_end = pos
				while word_end <= len and text:sub(word_end, word_end):match("[%w_]") do
					word_end = word_end + 1
				end
				local word_chunk = text:sub(pos, word_end - 1)
				if lua_keywords[word_chunk] then
					table.insert(out, cols.keyword)
				else
					table.insert(out, cols.text)
				end
				table.insert(out, word_chunk)
				pos = word_end
			elseif c:match("%p") then
				table.insert(out, cols.operator)
				table.insert(out, c)
				pos = pos + 1
			else
				table.insert(out, cols.text)
				table.insert(out, c)
				pos = pos + char_len
			end
		end
		if #out == 0 then
			table.insert(out, cols.text); table.insert(out, "")
		end
		return out
	end

	loveframes.lexers.xml = function(text, cols)
		local out = {}
		local pos = 1
		local len = #text
		local in_tag = false
		while pos <= len do
			local byte = string.byte(text, pos)
			local char_len = 1
			if byte >= 192 and byte <= 223 then
				char_len = 2
			elseif byte >= 224 and byte <= 239 then
				char_len = 3
			elseif byte >= 240 and byte <= 247 then
				char_len = 4
			end

			local c = text:sub(pos, pos + char_len - 1)

			if text:sub(pos, pos + 3) == "<!--" then
				table.insert(out, cols.comment)
				table.insert(out, text:sub(pos))
				break
			elseif c == '<' then
				in_tag = true
				table.insert(out, cols.keyword)
				table.insert(out, c)
				pos = pos + 1
			elseif c == '>' then
				in_tag = false
				table.insert(out, cols.keyword)
				table.insert(out, c)
				pos = pos + 1
			elseif in_tag and (c == '"' or c == "'") then
				local end_pos = text:find(c, pos + 1)
				if not end_pos then end_pos = len end
				local str_chunk = text:sub(pos, end_pos)
				table.insert(out, cols.string)
				table.insert(out, str_chunk)
				pos = end_pos + 1
			elseif in_tag and c:match("[%a_]") then
				local word_end = pos
				while word_end <= len and text:sub(word_end, word_end):match("[%w_%-]") do
					word_end = word_end + 1
				end
				local word_chunk = text:sub(pos, word_end - 1)
				if pos > 1 and (text:sub(pos - 1, pos - 1) == "<" or (pos > 2 and text:sub(pos - 2, pos - 1) == "</")) then
					table.insert(out, cols.keyword)
				else
					table.insert(out, cols.text)
				end
				table.insert(out, word_chunk)
				pos = word_end
			elseif in_tag and c == "=" then
				table.insert(out, cols.operator)
				table.insert(out, c)
				pos = pos + 1
			elseif not in_tag and c:match("%s") then
				table.insert(out, cols.text)
				table.insert(out, c)
				pos = pos + char_len
			else
				table.insert(out, cols.text)
				table.insert(out, c)
				pos = pos + char_len
			end
		end
		if #out == 0 then
			table.insert(out, cols.text); table.insert(out, "")
		end
		return out
	end
	loveframes.lexers.html = loveframes.lexers.xml

	-- codebox object
	local CodeBox = loveframes.NewObject("codebox", "loveframes_object_codebox", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function CodeBox:initialize()
		self.type = "codebox"
		self.width = 200
		self.height = 25
		self.offsetx = 0
		self.offsety = 0

		-- Margin reserved for drawing line numbers
		self.linenumber_margin = 40

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
		self.mousewheelscrollamount = 20
		self.autoscroll = true

		self.OnEnter = nil
		self.OnKeyPressed = nil
		self.OnControlKeyPressed = nil
		self.OnTextChanged = nil
		self.OnFocusGained = nil
		self.OnFocusLost = nil
		self.OnCopy = nil
		self.OnPaste = nil

		-- Default syntax colors
		self.syntax_colors = {
			--keyword = { 0.34, 0.61, 0.84, 1.00 },
			keyword = { 0.58, 0.47, 0.75, 1.00 },
			string = { 0.81, 0.51, 0.30, 1.00 },
			number = { 0.65, 0.81, 0.61, 1.00 },
			comment = { 0.42, 0.48, 0.19, 1.00 },
			margin = { 0.18, 0.18, 0.18, 1 },
			lineno = { 1, 1, 1, 0.5 },
			body = { 0.12, 0.12, 0.12, 1.00 },
			text = { 0.61, 0.86, 0.85, 1.00 },
			operator = { 0.9, 0.9, 0.9, 1.00 },
			highlight = { 0.5, 0.5, 1, 0.5 },
			indicator = { 1, 1, 1, 1 },
			border = { 0.5, 0.5, 0.5, 1 }
		}
		self.Draw = self.DrawCodeBox

		-- Font properties
		local codebox_font
		local font_path = loveframes.GetSkinAsset("NotoSansMono-Regular.ttf")
		if font_path then
			codebox_font = love.graphics.newFont(font_path, 14)
		end
		self.font = codebox_font or loveframes.basicfont
		self.color = nil
		self.verticalpadding = 4
		self.horizontalpadding = 4

		-- Initialize the text input object
		self.field = loveframes.input()
		self.field:setType("multiwrap")
		self.field:setFont(self.font)
		self.field:setDimensions(self.width, self.height)
		self:SetMultiline(true)
		self.lexer = "lua"
		self.line_caches = {}
	end

	function CodeBox:SetLexer(lexer)
		self.lexer = lexer
		self.line_caches = {}
		return self
	end

	function CodeBox:GetLexer()
		return self.lexer
	end

	--[[---------------------------------------------------------
	- func: GetVerticalScrollBody()
	- desc: gets the object's vertical scroll body
--]] ---------------------------------------------------------
	function CodeBox:GetVerticalScrollBody()
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
--]] ---------------------------------------------------------
	function CodeBox:update(dt)
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
		end

		self.itemwidth = self.field:getTextWidth() + self.horizontalpadding
		self.itemheight = self.field:getTextHeight() + self.verticalpadding

		self.extrawidth = math.max(0, self.itemwidth - self.width)
		self.extraheight = math.max(0, self.itemheight - self.height)

		local fieldtype = self.field:getType()
		if self.itemheight > self.height and fieldtype ~= "normal" and fieldtype ~= "password" then
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

		-- Update children
		for k, v in ipairs(internals) do
			v:update(dt)
		end

		local scrollbody = self:GetVerticalScrollBody()
		if scrollbody then
			if scrollbody:IsAnchored() or self.vbar then
				self.field:setScroll(self.offsetx, self.offsety)
			end
		end
		-- Update the callback update function
		if update then
			update(self, dt)
		end
	end

	--[[---------------------------------------------------------
	- func: draw()
	- desc: draws the object
--]] ---------------------------------------------------------
	function CodeBox:draw()
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
--]] ---------------------------------------------------------
	function CodeBox:wheelmoved(x, y)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		local internals = self.internals
		for k, v in ipairs(internals) do
			v:wheelmoved(x, y)
		end
	end

	--[[---------------------------------------------------------
	- func: mousemoved(x, y, button)
	- desc: called when the player moves mouse
--]] ---------------------------------------------------------
	function CodeBox:mousemoved(x, y)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		if self.hover then
			self.field:mousemoved(x - self.x - self.linenumber_margin, y - self.y)
		end
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button) mousereleased(x, y, button)
	- desc: called when the player presses a mouse button
--]] ---------------------------------------------------------
	function CodeBox:mousepressed(x, y, button, istouch, presses)
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
			self.field:mousepressed(x - self.x - self.linenumber_margin, y - self.y, button, presses)
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

	function CodeBox:mousereleased(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		self.field:mousereleased(x - self.x - self.linenumber_margin, y - self.y, button)
	end

	--[[---------------------------------------------------------
	- func: keypressed(key, isrepeat) keyreleased(key, isrepeat)
	- desc: called when the player presses a key
--]] ---------------------------------------------------------
	function CodeBox:keypressed(key, isrepeat)
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
		local handled, textedited = self.field:keypressed(key, isrepeat)
		local focus = self.focus
		local oncopy = self.OnCopy
		local onpaste = self.OnPaste
		local oncut = self.OnCut
		local ontextchanged = self.OnTextChanged

		if (key == "backspace" or key == "delete" or textedited) and ontextchanged then
			ontextchanged(self, self.field:getText())
		end

		if loveframes.IsCtrlDown() and focus then
			if key == "c" then
				if oncopy then
					oncopy(self, love.system.getClipboardText())
				end
			elseif key == "x" then
				if oncut then
					oncut(self, love.system.getClipboardText())
				end
				if ontextchanged then
					ontextchanged(self, self.field:getText())
				end
			elseif key == "v" then
				if onpaste then
					onpaste(self, love.system.getClipboardText())
				end
				if ontextchanged then
					ontextchanged(self, self.field:getText())
				end
			end
		end
	end

	function CodeBox:keyreleased(key, isrepeat)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		if loveframes.inputobject ~= self then return end
	end

	--[[---------------------------------------------------------
	- func: textinput(text)
	- desc: called when the user inputs text
--]] ---------------------------------------------------------
	function CodeBox:textinput(text)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		if loveframes.inputobject ~= self then return end

		local ontextchanged = self.OnTextChanged
		local event, textedited = self.field:textinput(text)
		if event and textedited then
			if ontextchanged then
				ontextchanged(self, self.field:getText())
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
--]] ---------------------------------------------------------
	function CodeBox:SetFont(font)
		self.font = font
		self.field:setFont(font)
		return self
	end

	function CodeBox:GetFont()
		return self.font
	end

	function CodeBox:SetColor(r, g, b, a)
		if not self.color then
			self.color = { r, g, b, a }
			return self
		end
		self.color[1] = r or self.color[1]
		self.color[2] = g or self.color[2]
		self.color[3] = b or self.color[3]
		self.color[4] = a or self.color[4]
		return self
	end

	--[[---------------------------------------------------------
	- func: RedoLayout
	- desc: refresh the object layout
--]] ---------------------------------------------------------
	function CodeBox:RedoLayout()
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
--]] ---------------------------------------------------------
	function CodeBox:SetPadding(padding)
		self.verticalpadding = padding
		self.horizontalpadding = padding

		self.field:setDimensions(self.width - math.max(padding * 2, 0), self.height - math.max(padding * 2, 0))
		return self
	end

	function CodeBox:SetVerticalPadding(padding)
		self.verticalpadding = padding
		self.field:setHeight(self.height - math.max(padding * 2, 0))
		return self
	end

	function CodeBox:SetHorizontalPadding(padding)
		self.horizontalpadding = padding
		self.field:setWidth(self.width - math.max(padding * 2, 0))
		return self
	end

	--[[---------------------------------------------------------
	- func: GetPadding() GetVerticalPadding() GetHorizontalPadding()
	- desc: gets the object's padding
--]] ---------------------------------------------------------
	function CodeBox:GetPadding()
		return self.verticalpadding, self.horizontalpadding
	end

	function CodeBox:GetVerticalPadding()
		return self.verticalpadding
	end

	function CodeBox:GetHorizontalPadding()
		return self.horizontalpadding
	end

	--[[---------------------------------------------------------
	- func: SetFocus(focus) GetFocus()
	- desc: sets/gets the object's focus
--]] ---------------------------------------------------------
	function CodeBox:SetFocus(focus)
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

	function CodeBox:GetFocus()
		return self.focus
	end

	--[[---------------------------------------------------------
	- func: Clear()
	- desc: clears the object's text
--]] ---------------------------------------------------------
	function CodeBox:Clear()
		self.field:reset()
	end

	--[[---------------------------------------------------------
	- func: Cut()/Copy()/Paste()
	- desc: common text input features
--]] ---------------------------------------------------------
	function CodeBox:Cut()
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

	function CodeBox:Copy()
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

	function CodeBox:Paste()
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
--]] ---------------------------------------------------------
	function CodeBox:SetText(text)
		self.field:setText(text)
		return self
	end

	--[[---------------------------------------------------------
	- func: SetMultiline(text)
	- desc: sets the object's multiline functionality
--]] ---------------------------------------------------------
	function CodeBox:SetMultiline(bool)
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
--]] ---------------------------------------------------------
	---@param mode "multiwrap"|"multinowrap"|"password"|"normal"
	function CodeBox:SetType(mode)
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
--]] ---------------------------------------------------------
	function CodeBox:SetPasswordCharacter(character)
		self.field:setPasswordCharacter(character)
		return self
	end

	--[[---------------------------------------------------------
	- func: SetUsable(table)
	- desc: sets the object's allowed characters
--]] ---------------------------------------------------------
	function CodeBox:SetUsable(tbl)
		local filterFunction = function(input)
			local filter = tbl
			for k, v in pairs(filter) do
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
--]] ---------------------------------------------------------
	function CodeBox:SetUnusable(tbl)
		local filterFunction = function(input)
			local filter = tbl
			for k, v in pairs(filter) do
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
--]] ---------------------------------------------------------
	function CodeBox:SetCharacterLimit(limit)
		self.field:setCharacterLimit(limit)
		return self
	end

	--[[---------------------------------------------------------
	- func: SetPlaceholderText(text) GetPLaceholderText()
	- desc: sets the object's default text to display
--]] ---------------------------------------------------------
	function CodeBox:SetPlaceholderText(text)
		self.field:setPlaceholderText(text)
		return self
	end

	function CodeBox:GetPlaceholderText()
		return self.field:GetPlaceholderText()
	end

	--[[---------------------------------------------------------
	- func: GetText()
	- desc: gets the object's text
--]] ---------------------------------------------------------
	function CodeBox:GetText()
		return self.field:getText()
	end

	function CodeBox:GetFieldObject()
		return self.field
	end

	function CodeBox:MoveCursorTo(pos)
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

	function CodeBox:SetMaxHistory(size)
		self.field:setMaxHistory(size)
		return self
	end

	function CodeBox:SetSyntaxColor(type, r, g, b, a)
		if self.syntax_colors[type] then
			self.syntax_colors[type] = { r, g, b, a or 1 }
		end
		return self
	end

	function CodeBox:DrawCodeBox()
		local x = self.x
		local y = self.y
		local width = self:GetWidth()
		local height = self:GetHeight()
		local vpadding = self:GetVerticalPadding()
		local hpadding = self:GetHorizontalPadding()
		local focus = self:GetFocus()
		local field = self.field
		local font = self:GetFont()
		local font_height = font:getHeight()
		local blink_phase = field:getBlinkPhase()
		local margin = self.linenumber_margin

		local cols = self.syntax_colors
		love.graphics.setFont(font)

		-- Draw body
		love.graphics.setColor(unpack(cols.body))
		love.graphics.rectangle("fill", x, y, width, height)

		-- Draw line number margin
		love.graphics.setColor(unpack(cols.margin))
		love.graphics.rectangle("fill", x, y, margin, height)

		-- Draw the selected text
		love.graphics.setColor(unpack(cols.highlight))
		for _, selection_x, selection_y, selection_w, selection_h in field:eachSelection() do
			if selection_y >= -font_height and selection_y + selection_h <= height + font_height then
				love.graphics.rectangle("fill", selection_x + x + hpadding + margin, selection_y + y + vpadding,
					selection_w, selection_h)
			end
		end

		-- Draw text and line numbers
		for line_num, text, line_x, line_y in field:eachVisibleLine() do
			if line_y >= -font_height and line_y <= height + font_height then
				-- Draw line number
				love.graphics.setColor(unpack(cols.lineno))
				local ln_str = tostring(line_num)
				love.graphics.print(ln_str, x + margin - font:getWidth(ln_str) - 4, y + vpadding + line_y)

				-- Draw Syntax Highlighted Text
				local draw_x = x + hpadding + margin + line_x
				local draw_y = y + vpadding + line_y

				local colored_text = self.line_caches[text]
				if not colored_text then
					local lexer_fn = loveframes.lexers[self.lexer] or loveframes.lexers.lua
					colored_text = lexer_fn(text, cols)
					self.line_caches[text] = colored_text
				end
				-- Clear color before drawing colored text
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.print(colored_text, draw_x, draw_y)
			end
		end

		-- Draw cursor blinking
		if focus and (blink_phase / 0.90) % 1 < .5 then
			local cursor_x, cursor_y, cursor_height = field:getCursorLayout()
			if cursor_x >= 0 and cursor_x <= width - margin and cursor_y >= -font_height and cursor_y <= height + font_height then
				love.graphics.setColor(unpack(cols.indicator))
				love.graphics.rectangle("fill", cursor_x + x + hpadding + margin, cursor_y + y + vpadding, 1,
					cursor_height)
			end
		end

		-- Draw the scroll bar
		local hOffset, hCoverage, vOffset, vCoverage = field:getScrollHandles()
		local hHandleLength                          = hCoverage * (width - margin)
		local hHandlePos                             = hOffset * (width - margin)

		if hHandleLength < (width - margin) then
			love.graphics.setColor(unpack(cols.border))
			love.graphics.rectangle("fill", x + margin + hHandlePos, y + height - 2, hHandleLength, 2)
		end

		love.graphics.setColor(unpack(cols.border))
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", x, y, width, height)
	end

	function CodeBox:SetVisible(bool)
		self.visible = bool
		self.field:resetBlinking()
		return self
	end

	---------- module end ----------
end
