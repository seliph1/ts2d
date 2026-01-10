--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- button object
local newobject = loveframes.NewObject("textbutton", "loveframes_object_textbutton", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	-- Font properties
	local skin = loveframes.GetActiveSkin()
	local default_font = skin.directives.text_default_font

	self.type = "textbutton"
	self.width = 80
	self.height = 20
	self.internal = false
	self.down = false
	self.clickable = true
	self.enabled = true
	self.toggleable = false
	self.toggle = false
	self.OnClick = nil
	self.groupIndex = 0
	self.checked = false
	self.text = "Button"
	self.formattedtext = "Button"
	self.hovertext = ""
	self.formattedhovertext = ""
	self.align = "left"
	self.font = default_font or loveframes.basicfont
	self.defaultcolor = {1, 1, 1, 1}
	self.textmesh = love.graphics.newTextBatch(self.font, "")
	self.textmesh:setf(self.text, self.width, self.align)
	self.hovertextmesh = love.graphics.newTextBatch(self.font, "")
	self.hovertextmesh:setf(self.text, self.width, self.align)
	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function newobject:update(dt)
	if not self:OnState() then return end
	if not self:isUpdating() then return end

	self:CheckHover()
	local hover = self.hover
	local down = self.down
	local downobject = loveframes.downobject
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update
	if not hover then
		self.down = false
		if downobject == self then
			self.hover = true
		end
	else
		if downobject == self then
			self.down = true
		end
	end
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
	local visible = self.visible
	if not visible then
		return
	end
	local hover = self.hover
	if hover and button == 1 then
		local baseparent = self:GetBaseParent()
		if baseparent and baseparent.type == "frame" then
			baseparent:MakeTop()
		end
		self.down = true
		loveframes.downobject = self
	end
end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function newobject:mousereleased(x, y, button)
	if not self:OnState() then return end

	local hover = self.hover
	local down = self.down
	local clickable = self.clickable
	local enabled = self.enabled
	local onclick = self.OnClick
	if hover and down and clickable and button == 1 then
		if enabled then
			if self.groupIndex ~= 0 then
				local baseparent = self.parent
				if baseparent then
					for k, v in ipairs(baseparent.children) do
						if v.groupIndex then
							if v.groupIndex == self.groupIndex then
								v.checked = false
							end
						end
					end
				end
				self.checked = true
			end
			if onclick then
				onclick(self, x, y)
			end
			if self.toggleable then
				local ontoggle = self.OnToggle
				self.toggle = not self.toggle
				if ontoggle then
					ontoggle(self, self.toggle)
				end
			end
		end
	end
	self.down = false
end

--[[---------------------------------------------------------
	- func: SetText(text)
	- desc: sets the object's text
--]]---------------------------------------------------------
function newobject:RedoLayout()
	self:SetText(self.text)
	self:SetHoverText(self.hovertext)
	return self
end

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

	return formattedchunks, table.concat(formattedstring)
end

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
	- func: GetText()
	- desc: gets/sets the object's text and aligment
--]]---------------------------------------------------------
function newobject:SetText(text)
	if not text then
		text = ""
	end
	self.textmesh:clear()
	-- Validate UTF8 and fix broken strings
	text = self:fixUTF8(text, "?")
	-- Parse the string received
	local parsedtext, formattedtext = self:ParseText(text)
	-- Set the text cache
	self.textmesh:setf(parsedtext, self.width, self.align)
	-- Refresh the internal variables
	self.text = text
	self.formattedtext = formattedtext

	local width, height = self.textmesh:getDimensions()
	return self
end

function newobject:SetAlign(mode)
	self.align = mode
	self:RedoLayout()
	return self
end

function newobject:GetText()
	return self.text
end

function newobject:GetFormattedText()
	return self.formattedtext
end

function newobject:GetDrawableText()
	return self.textmesh
end

function newobject:GetAlign()
	return self.align
end


--[[---------------------------------------------------------
	- func: GetHoverText()
	- desc: gets/sets the object's text and aligment
--]]---------------------------------------------------------
function newobject:SetHoverText(text)
	if not text then
		text = ""
	end
	self.hovertextmesh:clear()
	-- Validate UTF8 and fix broken strings
	text = self:fixUTF8(text, "?")
	-- Parse the string received
	local parsedtext, formattedtext = self:ParseText(text)
	-- Set the text cache
	self.hovertextmesh:setf(parsedtext, self.width, self.align)
	-- Refresh the internal variables
	self.hovertext = text
	self.formattedhovertext = formattedtext

	return self
end

function newobject:GetHoverText()
	return self.hovertext
end

function newobject:GetFormattedHoverText()
	return self.formattedhovertext
end

function newobject:GetDrawableHoverText()
	return self.hovertextmesh
end

--[[---------------------------------------------------------
	- func: SetFont(font)
	- desc: sets the object's font
	- note: font argument must be a font object
--]]---------------------------------------------------------
function newobject:SetFont(font)
	if not font then
		font = loveframes.basicfont
	end
	self.font = font
	self.textmesh:setFont(font)
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
	- func: SetImage(image)
	- desc: adds an image to the object
--]]---------------------------------------------------------
function newobject:SetImage(image)
	if type(image) == "string" then
		self.image = love.graphics.newImage(image)
		self.image:setFilter("nearest", "nearest")
	else
		self.image = image
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetImage()
	- desc: gets the object's image
--]]---------------------------------------------------------
function newobject:GetImage()
	return self.image
end
--[[---------------------------------------------------------
	- func: SetClickable(bool)
	- desc: sets whether the object can be clicked or not
--]]---------------------------------------------------------
function newobject:SetClickable(bool)
	self.clickable = bool
	return self
end

--[[---------------------------------------------------------
	- func: GetClickable(bool)
	- desc: gets whether the object can be clicked or not
--]]---------------------------------------------------------
function newobject:GetClickable()
	return self.clickable
end

--[[---------------------------------------------------------
	- func: SetClickable(bool)
	- desc: sets whether or not the object is enabled
--]]---------------------------------------------------------
function newobject:SetEnabled(bool)
	self.enabled = bool
	return self
end

--[[---------------------------------------------------------
	- func: GetEnabled()
	- desc: gets whether or not the object is enabled
--]]---------------------------------------------------------
function newobject:GetEnabled()
	return self.enabled
end

--[[---------------------------------------------------------
	- func: GetDown()
	- desc: gets whether or not the object is currently
	        being pressed
--]]---------------------------------------------------------
function newobject:GetDown()
	return self.down
end

--[[---------------------------------------------------------
	- func: SetToggleable(bool)
	- desc: sets whether or not the object is toggleable
--]]---------------------------------------------------------
function newobject:SetToggleable(bool)
	self.toggleable = bool
	return self
end

--[[---------------------------------------------------------
	- func: GetToggleable()
	- desc: gets whether or not the object is toggleable
--]]---------------------------------------------------------
function newobject:GetToggleable()
	return self.toggleable
end


--[[---------------------------------------------------------
	- func: GetChecked()
	- desc: gets whether or not the object is checked
--]]---------------------------------------------------------
function newobject:GetChecked()
	return self.checked
end

--[[---------------------------------------------------------
	- func: SetChecked()
	- desc: sets the check status of this button
--]]---------------------------------------------------------
function newobject:SetChecked(bool)
	self.checked = bool
	return self
end
---------- module end ----------
end
