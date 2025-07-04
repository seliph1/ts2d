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

	self.type = "label"
	self.text = ""
	self.font = loveframes.basicfont
	self.width = 5
	self.height = 5
	self.maxw = 0
	self.lines = 0
	self.formattedtext = {}
	self.original = {}
	self.defaultcolor = {0, 0, 0, 1}
	self.ignorenewlines = false
	self.shadow = false
	self.linkcol = false
	self.internal = false
	self.linksenabled = false
	self.detectlinks = false
	self.OnClickLink = nil
	
	local skin = loveframes.GetActiveSkin()
	if not skin then
		skin = loveframes.config["DEFAULTSKIN"]
	end
	
	local directives = skin.directives
	if directives then
		local text_default_color = directives.tooltip_default_color
		local text_default_font = directives.tooltip_default_font
		
		if text_default_color then
			self.defaultcolor = text_default_color
		end
		if text_default_font then
			self.font = text_default_font
		end
	end
	self:SetDrawFunc()
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
	
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update
	
	if parent.type ~= "tooltip" then
		self:CheckHover()
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
function newobject:SetText(t)
	
	local dtype = type(t)
	local maxw = self.maxw
	local font = self.font
	local defaultcolor = self.defaultcolor
	local inserts = {}
	local prevcolor = defaultcolor
	local prevfont = font
	local tdata
	
	self.text = ""
	self.formattedtext = {}
	
	if dtype == "string" then
		tdata = {t}
		self.original = {t}
	elseif dtype == "number" then
		tdata = {tostring(t)}
		self.original = {tostring(t)}
	elseif dtype == "table" then
		tdata = t
		self.original = t
	else
		return
	end
	
	for k, v in ipairs(tdata) do
		dtype = type(v)
		if dtype == "table" then
			if v.color then
				prevcolor = v.color
			end
		elseif dtype == "number" then
			table.insert(self.formattedtext, {
				font = prevfont, 
				color = prevcolor, 
				text = tostring(v)
			})
		elseif dtype == "string" then
			if self.ignorenewlines then
				v = loveframes.utf8.gsub(v, "\n", " ")
			end
			v = loveframes.utf8.gsub(v, string.char(9), "    ")
			v = loveframes.utf8.gsub(v, "\n", " \n ")
			local parts = loveframes.SplitString(v, " ")
			for i, j in ipairs(parts) do
				table.insert(self.formattedtext, {
					font = prevfont, 
					color = prevcolor, 
					text = j
				})
			end
		end
	end
	
	if maxw > 0 then
		for k, v in ipairs(self.formattedtext) do
			local data = v.text
			local width = v.font:getWidth(data)
			local curw = 0
			local new = ""
			local key = k
			if width > maxw then
				table.remove(self.formattedtext, k)
				for n=1, loveframes.utf8.len(data) do	
					local item = loveframes.utf8.sub(data, n, n)
					local itemw = v.font:getWidth(item)
					if n ~= loveframes.utf8.len(data) then
						if (curw + itemw) > maxw then
							table.insert(inserts, {
								key = key, 
								font = v.font, 
								color = v.color, 
								text = new
							})
							new = item
							curw = 0 + itemw
							key = key + 1
						else
							new = new .. item
							curw = curw + itemw
						end
					else
						new = new .. item
						table.insert(inserts, {
							key = key, 
							font = v.font, 
							color = v.color, 
							text = new
						})
					end
				end
			end
		end
	end
	
	for k, v in ipairs(inserts) do
		table.insert(self.formattedtext, v.key, {
			font = v.font, 
			color = v.color, 
			text = v.text
		})
	end
	
	local textdata = self.formattedtext
	local maxw = self.maxw
	local font = self.font
	local twidth = 0
	local drawx = 0
	local drawy = 0
	local lines = 1
	local textwidth = 0
	local lastwidth = 0
	local totalwidth = 0
	local x = self.x
	local y = self.y
	local prevtextwidth = 0
	local prevtextheight = 0
	local prevlargestheight = 0
	local largestwidth = 0
	local largestheight = 0
	local initialwidth = 0
	
	for k, v in ipairs(textdata) do
		local text = v.text
		local color = v.color
		if type(text) == "string" then
			self.text = self.text .. text
			local width = v.font:getWidth(text)
			local height = v.font:getHeight("a")
			if height > largestheight then
				largestheight = height
				prevlargestheight = height
			end
			totalwidth = totalwidth + width
			if maxw > 0 then
				if k ~= 1 then
					if string.byte(text) == 10 then
						twidth = 0
						drawx = 0
						width = 0
						drawy = drawy + largestheight
						largestheight = 0
						text = ""
						lines = lines + 1
					elseif (twidth + width) > maxw then
						twidth = 0 + width
						drawx = 0
						drawy = drawy + largestheight
						largestheight = 0
						lines = lines + 1
					else
						twidth = twidth + width
						drawx = drawx + prevtextwidth
					end
				else
					twidth = twidth + width
				end
				prevtextwidth = width
				prevtextheight = height
				v.x = drawx
				v.y = drawy
			else
				if string.byte(text) == 10 then
					twidth = 0
					drawx = 0
					width = 0
					drawy = drawy + largestheight
					largestheight = 0
					text = ""
					lines = lines + 1
					if lastwidth < textwidth then
						lastwidth = textwidth
					end
					if largestwidth < textwidth then
						largestwidth = textwidth
					end
					textwidth = 0
				else
					drawx = drawx + prevtextwidth
					textwidth = textwidth + width
				end
				prevtextwidth = width
				prevtextheight = height
				v.x = drawx
				v.y = drawy
			end
		end
	end
	
	self.lines = lines
	
	if lastwidth == 0 then
		textwidth = totalwidth
	end
	
	if textwidth < largestwidth then
		textwidth = largestwidth
	end
	
	if maxw > 0 then
		self.width = maxw
	else
		self.width = textwidth
	end
	
	self.height = drawy + prevlargestheight
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
	- func: GetFormattedText()
	- desc: gets the object's formatted text
--]]---------------------------------------------------------
function newobject:GetFormattedText()

	return self.formattedtext
	
end

--[[---------------------------------------------------------
	- func: DrawText()
	- desc: draws the object's text
--]]---------------------------------------------------------
function newobject:DrawText()
	local textdata = self.formattedtext
	local x = self.x
	local y = self.y
	
	--local inlist, list = object:IsInList()
	local printfunc = function(text, x, y)
		love.graphics.print(text, math.floor(x + 0.5), math.floor(y + 0.5))
	end
	for k, v in ipairs(textdata) do
		local textx = v.x
		local texty = v.y
		local text = v.text
		local color = v.color
		local font = v.font
		local theight = font:getHeight("a")
		love.graphics.setFont(font)
		love.graphics.setColor(unpack(color))
		printfunc(text, x + textx, y + texty)
	end	
	return self
end

--[[---------------------------------------------------------
	- func: SetMaxWidth(width)
	- desc: sets the object's maximum width
--]]---------------------------------------------------------
function newobject:SetMaxWidth(width)

	local original = self.original
	
	self.maxw = width
	self:SetText(original)
	
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
	
	return
	
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

--[[---------------------------------------------------------
	- func: GetLines()
	- desc: gets the number of lines the object's text uses
--]]---------------------------------------------------------
function newobject:GetLines()

	return self.lines
	
end

--[[---------------------------------------------------------
	- func: SetIgnoreNewlines(bool)
	- desc: sets whether the object should ignore \n or not
--]]---------------------------------------------------------
function newobject:SetIgnoreNewlines(bool)

	self.ignorenewlines = bool
	return self
	
end

--[[---------------------------------------------------------
	- func: GetIgnoreNewlines()
	- desc: gets whether the object should ignore \n or not
--]]---------------------------------------------------------
function newobject:GetIgnoreNewlines()

	return self.ignorenewlines
	
end

--[[---------------------------------------------------------
	- func: SetDefaultColor(r, g, b, a)
	- desc: sets the object's default text color
--]]---------------------------------------------------------
function newobject:SetDefaultColor(r, g, b, a)

	self.defaultcolor = {r, g, b, a}
	return self
	
end

--[[---------------------------------------------------------
	- func: GetDefaultColor()
	- desc: gets whether or not the object should draw a
			shadow behind its text
--]]---------------------------------------------------------
function newobject:GetDefaultColor()

	return self.defaultcolor
	
end
---------- module end ----------
end
