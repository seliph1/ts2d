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
local MessageBox = loveframes.NewObject("messagebox", "loveframes_object_messagebox", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function MessageBox:initialize()
	-- Font properties
	local skin = loveframes.GetActiveSkin()
	local default_font = skin.directives.text_default_font

	self.type = "messagebox"
	self.text = ""
	self.formattedtext = ""
	self.shadow = true
	self.font = default_font or loveframes.basicfont
	self.defaultcolor = {1,1,1,1}
	self.textmesh = love.graphics.newTextBatch(self.font, "")

	self.maxwidth = 100
	self.width = 100
	self.height = self.font:getHeight()
	self.internal = false
	self:SetDrawFunc()
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function MessageBox:update(dt)
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
function MessageBox:mousepressed(x, y, button)
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
function MessageBox:fixUTF8(s, replacement)
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

function MessageBox:SetText(text)
	self.textmesh:clear()
	-- Fix the text
	text = self:fixUTF8(text," ")

	-- Parse the obtained string with cs2d formatting
	local parsedtext, formattedtext = self:ParseText(text)

	-- Add the fixed, formatted text to the texthash object
	local status, err = pcall(
		self.textmesh.setf,
		self.textmesh,
		parsedtext,
		self.maxwidth,
		"left"
	)
	if not status then
		self.textmesh:setf(tostring(err), self.maxwidth, "left")
	end

	self.text = text
	self.formattedtext = formattedtext


	local width, height = self.textmesh:getDimensions()
	self:SetSize(width, height)

	return self
end

--[[---------------------------------------------------------
	- func: ParseText(text)
	- desc: parses the text of this object
--]]---------------------------------------------------------
function MessageBox:ParseText(str)
	local formattedchunks = {}
	local formattedstring = {}
	local defaultColor = self.defaultcolor
	local currentColor = {0,0,0,1}

	local last = 1
	while true do
		local i, j = str:find("©", last)
		if not i then
			-- restante
			table.insert(formattedchunks, defaultColor)
			table.insert(formattedchunks, str:sub(last))
			table.insert(formattedstring, str:sub(last))
			break
		end

		-- trecho antes do ©
		if i > last then
			local segment = str:sub(last, i-1)
			table.insert(formattedchunks, defaultColor)
			table.insert(formattedchunks, segment)
			table.insert(formattedstring, segment)
		end

		-- agora pega o próximo trecho até o próximo © ou fim
		local k = str:find("©", j+1) or (#str+1)
		local capture = str:sub(j+1, k-1)

		local r,g,b = capture:match("(%d%d%d)(%d%d%d)(%d%d%d)")
		local text = capture:sub(10)
		if r and g and b then
			table.insert(formattedchunks, {tonumber(r)/255, tonumber(g)/255, tonumber(b)/255})
			table.insert(formattedchunks, text)
			table.insert(formattedstring, text)
		else
			-- não é cor válida, volta o texto inteiro
			local bad = "©"..capture
			local previousColor
			if #formattedchunks > 0 then
				previousColor = formattedchunks[#formattedchunks-2]
			else
				previousColor = defaultColor
			end
			table.insert(formattedchunks, previousColor)
			table.insert(formattedchunks, bad)
			table.insert(formattedstring, bad)
		end
		last = k
	end

	return formattedchunks, table.concat(formattedstring)
end
--[[---------------------------------------------------------
	- func: GetText()
	- desc: gets the object's text
--]]---------------------------------------------------------
function MessageBox:GetText()
	return self.text
end
--[[---------------------------------------------------------
	- func: GetFormattedText()
	- desc: gets the object's formatted text
--]]---------------------------------------------------------
function MessageBox:GetFormattedText()
	return self.formattedtext
end

--[[---------------------------------------------------------
	- func: SetMaxWidth(width)
	- desc: sets the object's maximum width
--]]---------------------------------------------------------
function MessageBox:SetMaxWidth(width)
	if width >= 0 and width <= 1 then
		width = self.parent.width * width
	end
	self.maxwidth = math.floor(width)
	return self
end

--[[---------------------------------------------------------
	- func: GetMaxWidth()
	- desc: gets the object's maximum width
--]]---------------------------------------------------------
function MessageBox:GetMaxWidth()
	return self.maxwidth
end

--[[---------------------------------------------------------
	- func: SetFont(font)
	- desc: sets the object's font
	- note: font argument must be a font object
--]]---------------------------------------------------------
function MessageBox:SetFont(font)
	self.font = font
	-- Refresh the text width size
	self.textmesh:setFont(font)
	-- Resize the message width/height
	local width, height = self.textmesh:getDimensions()
	width = math.max(width, self.maxwidth)
	height = math.max(height, self.font:getHeight())

	self:SetSize(width, height)
	return self
end

--[[---------------------------------------------------------
	- func: GetFont()
	- desc: gets the object's font
--]]---------------------------------------------------------
function MessageBox:GetFont()
	return self.font
end

--[[---------------------------------------------------------
	- func: SetShadow(bool) GetShadow(bool)
	- desc: sets the object's shadow
--]]---------------------------------------------------------
function MessageBox:SetShadow(bool)
    self.shadow = bool
	return self
end
function MessageBox:GetShadow(bool)
    return self.shadow
end

---------- module end ----------
end
