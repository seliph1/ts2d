--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

--[[------------------------------------------------
	-- sysl: a dialogue/message box backed by the
	-- SYSL-Text library (loveframes.sysl). Prints text
	-- with a typewriter effect, wraps it to the object's
	-- width and advances page-by-page on click. Usable on
	-- its own or driven by the event system.
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- sysl object
local newobject = loveframes.NewObject("sysl", "loveframes_object_sysl", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	local skin = loveframes.skins[loveframes.config["ACTIVESKIN"]]
	local directives = skin and skin.directives

	self.type = "sysl"
	self.text = ""
	self.font = (directives and directives.text_default_font) or loveframes.basicfont
	self.width = 400
	self.height = 100
	self.padding = 12
	self.wrap = nil          -- nil = derive from width/padding
	self.internal = false

	-- Page queue and printing state.
	self.pages = {}
	self.page = 0
	self.done = false
	self.blink = 0

	-- Initialize the text library
	self.field = loveframes.sysl.new("left", {
		font = self.font,
		color = {1, 1, 1, 1},
		shadow_color = {0.5, 0.5, 1, 0.4},
		keep_space_on_line_break = true,
		default_underline_position = -2,
		default_strikethrough_position = 1
	})

	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function newobject:update(dt)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update
	self:CheckHover()
	-- move to parent if there is a parent
	if parent ~= base then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end

	self.field:update(dt)
	self.blink = self.blink + dt

	if update then
		update(self, dt)
	end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button)
	if not self.visible then return end
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	if self.hover and button == 1 then
		local baseparent = self:GetBaseParent()
		if baseparent and baseparent.type == "frame" then
			baseparent:MakeTop()
		end
		-- A click reveals the rest of the current page, or moves on.
		self:Advance()
	end
end

--[[---------------------------------------------------------
	- func: fixUTF8(s, replacement)
	- desc: replaces invalid UTF8 sequences so the library
			never chokes on bad input
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

--[[---------------------------------------------------------
	- func: GetWrapWidth()
	- desc: the pixel width text is wrapped at
--]]---------------------------------------------------------
function newobject:GetWrapWidth()
	return self.wrap or math.max(1, self.width - self.padding * 2)
end

--[[---------------------------------------------------------
	- func: SendCurrent()
	- desc: (internal) hands the current page to the text
			library, starting the typewriter effect
--]]---------------------------------------------------------
function newobject:SendCurrent()
	local text = self.pages[self.page]
	if not text then return end
	self.blink = 0
	self.field:send(self:fixUTF8(text, "?"), self:GetWrapWidth())
end

--[[---------------------------------------------------------
	- func: SetText(text)
	- desc: shows a single message, replacing any queue
--]]---------------------------------------------------------
function newobject:SetText(text)
	self.text = text
	self.pages = {text}
	self.page = 1
	self.done = false
	self:SendCurrent()
	return self
end

--[[---------------------------------------------------------
	- func: SetMessages(list)
	- desc: queues several messages, shown one page at a time
--]]---------------------------------------------------------
function newobject:SetMessages(list)
	self.pages = list or {}
	self.page = (#self.pages > 0) and 1 or 0
	self.done = false
	self.text = self.pages[self.page] or ""
	if self.page > 0 then
		self:SendCurrent()
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetText()
	- desc: gets the object's current page text
--]]---------------------------------------------------------
function newobject:GetText()
	return self.text
end

--[[---------------------------------------------------------
	- func: IsFinished()
	- desc: true once the current page has fully printed
--]]---------------------------------------------------------
function newobject:IsFinished()
	if self.page == 0 then return true end
	return self.field:is_finished()
end

--[[---------------------------------------------------------
	- func: IsDone()
	- desc: true once the whole queue has been shown and
			dismissed
--]]---------------------------------------------------------
function newobject:IsDone()
	return self.done
end

--[[---------------------------------------------------------
	- func: Skip()
	- desc: instantly reveals the rest of the current page
--]]---------------------------------------------------------
function newobject:Skip()
	local field = self.field
	field.current_character = #field.table_string
	return self
end

--[[---------------------------------------------------------
	- func: Advance()
	- desc: skips the typewriter if still printing, otherwise
			moves to the next page (or completes the queue)
--]]---------------------------------------------------------
function newobject:Advance()
	if self.page == 0 then return self end
	if not self:IsFinished() then
		self:Skip()
		return self
	end
	if self.page < #self.pages then
		self.page = self.page + 1
		self.text = self.pages[self.page]
		self:SendCurrent()
	else
		self.done = true
		if self.OnComplete then
			self.OnComplete(self)
		end
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetWrap(width)
	- desc: overrides the wrap width (nil derives it from the
			object's width)
--]]---------------------------------------------------------
function newobject:SetWrap(width)
	self.wrap = width
	if self.page > 0 then
		self:SendCurrent()
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetWrap()
	- desc: gets the explicit wrap width (may be nil)
--]]---------------------------------------------------------
function newobject:GetWrap()
	return self.wrap
end

--[[---------------------------------------------------------
	- func: SetPadding(padding)
	- desc: sets the inner padding around the text
--]]---------------------------------------------------------
function newobject:SetPadding(padding)
	self.padding = padding
	if self.page > 0 then
		self:SendCurrent()
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetPadding()
	- desc: gets the inner padding around the text
--]]---------------------------------------------------------
function newobject:GetPadding()
	return self.padding
end

--[[---------------------------------------------------------
	- func: SetPrintSpeed(speed)
	- desc: seconds between each printed character (lower is
			faster)
--]]---------------------------------------------------------
function newobject:SetPrintSpeed(speed)
	self.field.default_print_speed = speed
	self.field.current_print_speed = speed
	return self
end

--[[---------------------------------------------------------
	- func: SetFont(font)
	- desc: sets the object's font
	- note: font argument must be a font object
--]]---------------------------------------------------------
function newobject:SetFont(font)
	self.font = font
	self.field.default_font = font
	if self.page > 0 then
		self:SendCurrent()
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetFont()
	- desc: gets the object's font
--]]---------------------------------------------------------
function newobject:GetFont()
	return self.font
end

---------- module end ----------
end
