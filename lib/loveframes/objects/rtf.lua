--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

--[[------------------------------------------------
	-- note: the text wrapping of this object is
			 experimental and not final
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- label object
local newobject = loveframes.NewObject("rtf", "loveframes_object_rtf", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	self.type = "rtf"
	self.text = ""
	self.formattedtext = ""
	self.parsedtext = ""
	self.font = loveframes.basicfont
	self.width = 100
	self.height = 100
	self.internal = false

	-- Initialize the text library
	self.field = loveframes.sysl.new("left", {
		color = {1,1,1,1},
		shadow_color = {0.5,0.5,1,0.4},
		keep_space_on_line_break=true,
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

	if update then
		update(self, dt)
	end
end

--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]]---------------------------------------------------------
function newobject:mousepressed(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local hover = self.hover
	if hover and button == 1 then
		local baseparent = self:GetBaseParent()
		if baseparent and baseparent.type == "frame" then
			baseparent:MakeTop()
		end
	end
end

--[[---------------------------------------------------------
	- func: SetText(text)
	- desc: sets the object's text
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
function newobject:SetText(text)
	-- Validate UTF8 string
    self.text =  self:fixUTF8(text, "?")
	--self:ParseText()
	self.field:send(text)
	return self
end

--[[---------------------------------------------------------
	- func: ParseText(text)
	- desc: parses the text of this object
--]]---------------------------------------------------------
function newobject:ParseText()

end
--[[---------------------------------------------------------
	- func: GetText()
	- desc: gets the object's text
--]]---------------------------------------------------------
function newobject:GetText()
	return self.text
end
--[[---------------------------------------------------------
	- func: GetFormattedText()
	- desc: gets the object's formatted text
--]]---------------------------------------------------------
function newobject:GetFormattedText()
	return self.formattedtext
end

--[[---------------------------------------------------------
	- func: SetMaxWidth(width)
	- desc: sets the object's maximum width
--]]---------------------------------------------------------
function newobject:SetMaxWidth(width)
	self.maxw = width
	return self
end

--[[---------------------------------------------------------
	- func: GetMaxWidth()
	- desc: gets the object's maximum width
--]]---------------------------------------------------------
function newobject:GetMaxWidth()
	return self.maxw
end

--[[---------------------------------------------------------
	- func: SetWidth(width, relative)
	- desc: sets the object's width
--]]---------------------------------------------------------
function newobject:SetWidth(width, relative)
	if relative then
		self:SetMaxWidth(self.parent.width * width)
	else
		self:SetMaxWidth(width)
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetHeight()
	- desc: sets the object's height
--]]---------------------------------------------------------
function newobject:SetHeight(height)
	self.height = height
	return self
end
--[[---------------------------------------------------------
	- func: GetHeight()
	- desc: sets the object's height
--]]---------------------------------------------------------
function newobject:GetHeight(height)
	return self.height
end

--[[---------------------------------------------------------
	- func: SetSize(width, height, relative)
	- desc: sets the object's size
--]]---------------------------------------------------------
function newobject:SetSize(width, height, relative)
	if relative then
		self:SetMaxWidth(self.parent.width * width)
	else
		self:SetMaxWidth(width)
	end
	self.SetHeight(height)
	return self
end

--[[---------------------------------------------------------
	- func: SetFont(font)
	- desc: sets the object's font
	- note: font argument must be a font object
--]]---------------------------------------------------------
function newobject:SetFont(font)
	local original = self.original
	self.font = font
	if original then
		self:SetText(original)
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
