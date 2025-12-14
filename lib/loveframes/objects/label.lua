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
local newobject = loveframes.NewObject("label", "loveframes_object_label", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	-- Font properties
	local skin = loveframes.GetActiveSkin()
	local default_font = skin.directives.text_default_font
	local default_color = skin.directives.text_default_color

	self.type = "label"
	self.text = ""
	self.defaultcolor = default_color or {1,1,1,1}
	self.font = default_font or loveframes.basicfont
	self.textmesh = love.graphics.newTextBatch(self.font, "")

	self.width = self.font:getWidth(" ")
	self.height = self.width
	self.max_width = 200
	self.internal = false

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
	-- Check if the parent is a checkbox/radiobutton to propagate hover status
	if parent.type == "checkbox" or parent.type == "radiobutton" then
		parent:CheckHover()
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
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local hover = self.hover
	local onclick = self.OnClick

	if hover then
		local baseparent = self:GetBaseParent()
		if baseparent and baseparent.type == "frame" then
			baseparent:MakeTop()
		end
		if onclick then
			onclick(self, button)
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
    local fixedstring =  self:fixUTF8(text, "?")
	-- Parse the string received
	self.textmesh:set(fixedstring)
	-- Set the text cache
	self.text = fixedstring
	-- Resize the message width/height
	self:SetSize( self.textmesh:getWidth(), self.textmesh:getHeight() )
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
	- func: SetMaxWidth(width)
	- desc: sets the object's maximum width
--]]---------------------------------------------------------
function newobject:SetMaxWidth(width)
	self.max_width = width
	return self
end

--[[---------------------------------------------------------
	- func: GetMaxWidth()
	- desc: gets the object's maximum width
--]]---------------------------------------------------------
function newobject:GetMaxWidth()
	return self.max_width
end
--[[---------------------------------------------------------
	- func: SetFont(font)
	- desc: sets the object's font
	- note: font argument must be a font object
--]]---------------------------------------------------------
function newobject:SetFont(font)
	self.font = font
	self.textmesh:setFont(font)
	return self
end

function newobject:SetColor(r,g,b,a)
	self.defaultcolor[1] = r or self.defaultcolor[1]
	self.defaultcolor[2] = g or self.defaultcolor[2]
	self.defaultcolor[3] = b or self.defaultcolor[3]
	self.defaultcolor[4] = a or self.defaultcolor[4]
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
