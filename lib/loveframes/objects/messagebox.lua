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
local newobject = loveframes.NewObject("messagebox", "loveframes_object_messagebox", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	-- Font properties
	local skin = loveframes.GetActiveSkin()
	local default_font = skin.directives.text_default_font
	local default_color = skin.directives.text_default_color

	self.type = "messagebox"
	self.text = ""
	self.hovertext = ""
	self.formattedtext = ""
	self.formattedhovertext = ""
	self.defaultcolor = default_color or {1,1,1,1}
	self.hoverenabled = false
	self.font = default_font or loveframes.basicfont
	self.textmesh = love.graphics.newText(self.font, "")
	self.hovertextmesh = love.graphics.newText(self.font, "")

	self.width = self.font:getWidth(" ")
	self.height = self.width
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
	local formattedchunks, formattedstring = self:ParseText(fixedstring)
	-- Set the text cache
	self.textmesh:set(formattedchunks)
	self.formattedtext = formattedstring
	self.text = fixedstring
	-- Resize the message width/height
	self.width = self.textmesh:getWidth()
	self.height = self.textmesh:getHeight()

	return self
end

function newobject:SetHoverText(text)
	if text == "" then
		self.hoverenabled = false
	end

	-- Validate UTF8 string
    local fixedstring =  self:fixUTF8(text, "?")
	-- Parse the string received
	local formattedchunks, formattedstring = self:ParseText(fixedstring)
	-- Set the text cache
	self.hovertextmesh:set(formattedchunks)
	self.formattedhovertext = formattedstring
	self.hovertext = fixedstring
	-- Dont resize..
	--self.width = forget
	--self.height = about it
	self.hoverenabled = true
	return self
end

--[[---------------------------------------------------------
	- func: ParseText(text)
	- desc: parses the text of this object
--]]---------------------------------------------------------
function newobject:ParseText(str)
	local formattedchunks = {}
	local formattedstring = {}
    local defaultColor = self.defaultcolor

	if not str:find("©") then
		return {defaultColor,str}, str
	end

	for leading, capture in string.gmatch(str, "(.-)©([^©]+)") do
		--print(color, text)
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

	return formattedchunks, formattedstring
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
	self.font = font
	self.textmesh:setFont(font)
	self.hovertextmesh:setFont(font)

	-- Refresh the text width size
	-- Resize the message width/height
	self.width = self.textmesh:getWidth()
	self.height = self.textmesh:getHeight()
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
