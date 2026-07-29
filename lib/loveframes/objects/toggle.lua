--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- toggle object
local newobject = loveframes.NewObject("toggle", "loveframes_object_toggle", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function newobject:initialize()
	local skin = loveframes.GetActiveSkin()
	local font = skin.controls.toggle_text_font or loveframes.basicfont

	self.type = "toggle"
	self.width = 0
	self.height = 0
	self.boxwidth = 36
	self.boxheight = 18
	self.font = font
	self.checked = false
	self.internal = false
	self.down = false
	self.enabled = true
	self.internals = {}
	self.OnChanged = nil
	self.grayable = true
	self.direction = "horizontal"
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
	local internals = self.internals
	local boxwidth = self.boxwidth
	local boxheight = self.boxheight
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update

	if not hover then
		self.down = false
	else
		if loveframes.downobject == self then
			self.down = true
		end
	end

	if not self.down and loveframes.downobject == self then
		self.hover = true
	end

	-- move to parent if there is a parent
	if parent ~= base then
		self.x = self.parent.x + self.staticx
		self.y = self.parent.y + self.staticy
	end

	if internals[1] then
		if self.direction == "vertical" then
			self.height = boxheight + 5 + internals[1].height
			self.width = math.max(boxwidth, internals[1].width)
		else
			self.width = boxwidth + 5 + internals[1].width
			if internals[1].height > boxheight then
				self.height = internals[1].height
			else
				self.height = boxheight
			end
		end
	else
		self.width = boxwidth
		self.height = boxheight
	end

	for k, v in ipairs(internals) do
		v:update(dt)
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

	if self.hover and button == 1 then
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
	if not self:isUpdating() then return end

	if self.hover and self.down and self.enabled and button == 1 then
		self:SetChecked(not self.checked)
	end

	self.down = false
end

--[[---------------------------------------------------------
	- func: SetText(text)
	- desc: sets the object's text
--]]---------------------------------------------------------
function newobject:SetText(text)
	text = text or ""

	if text ~= "" then
		self.internals = {}
		local textobject = loveframes.Create("label")
		textobject:Remove()
		textobject.parent = self
		textobject.state = self.state
		textobject:SetFont(self.font)
		textobject:SetText(text)
		textobject.Update = function(object, dt)
			local parent = object.parent
			local boxwidth = parent.boxwidth
			local boxheight = parent.boxheight

			if parent.direction == "vertical" then
				object:SetPos(parent.width / 2 - object.width / 2, boxheight + 5)
			else
				if object.height > boxheight then
					object:SetPos(boxwidth + 5, 0)
				else
					object:SetPos(boxwidth + 5, boxheight / 2 - object.height / 2)
				end
			end
		end
		table.insert(self.internals, textobject)
	else
		self.width = self.boxwidth
		self.height = self.boxheight
		self.internals = {}
	end

	return self
end

--[[---------------------------------------------------------
	- func: GetText()
	- desc: gets the object's text
--]]---------------------------------------------------------
function newobject:GetText()
	local internals = self.internals
	local text = internals[1]
	if text then
		return text.text
	else
		return false
	end
end

--[[---------------------------------------------------------
	- func: SetSize(width, height, r1, r2)
	- desc: sets the object's switch size
--]]---------------------------------------------------------
function newobject:SetSize(width, height, r1, r2)
	if r1 then
		self.boxwidth = self.parent.width * width
	else
		self.boxwidth = width
	end
	if r2 then
		self.boxheight = self.parent.height * height
	else
		self.boxheight = height
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetWidth(width, relative)
	- desc: sets the object's switch width
--]]---------------------------------------------------------
function newobject:SetWidth(width, relative)
	if relative then
		self.boxwidth = self.parent.width * width
	else
		self.boxwidth = width
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetHeight(height, relative)
	- desc: sets the object's switch height
--]]---------------------------------------------------------
function newobject:SetHeight(height, relative)
	if relative then
		self.boxheight = self.parent.height * height
	else
		self.boxheight = height
	end
	return self
end

--[[---------------------------------------------------------
	- func: SetChecked(bool)
	- desc: sets whether the object is checked or not
--]]---------------------------------------------------------
function newobject:SetChecked(bool)
	bool = not not bool

	if self.checked ~= bool then
		self.checked = bool
		if self.OnChanged then
			self.OnChanged(self, self.checked)
		end
	end

	return self
end

--[[---------------------------------------------------------
	- func: GetChecked()
	- desc: gets whether the object is checked or not
--]]---------------------------------------------------------
function newobject:GetChecked()
	return self.checked
end

function newobject:SetValue(bool)
	return self:SetChecked(bool)
end

function newobject:SetDirection(dir)
	self.direction = dir
	if dir == "vertical" then
		self.boxwidth = 18
		self.boxheight = 36
	else
		self.boxwidth = 36
		self.boxheight = 18
	end
	return self
end

function newobject:GetDirection()
	return self.direction
end

function newobject:GetValue()
	return self:GetChecked()
end

--[[---------------------------------------------------------
	- func: SetFont(font)
	- desc: sets the font of the object's text
--]]---------------------------------------------------------
function newobject:SetFont(font)
	local internals = self.internals
	local text = internals[1]
	self.font = font
	if text then
		text:SetFont(font)
		text:SetText(text.text)
	end
	return self
end

--[[---------------------------------------------------------
	- func: GetFont()
	- desc: gets the font of the object's text
--]]---------------------------------------------------------
function newobject:GetFont()
	return self.font
end

--[[---------------------------------------------------------
	- func: GetBoxSize()
	- desc: gets the object's switch size
--]]---------------------------------------------------------
function newobject:GetBoxSize()
	return self.boxwidth, self.boxheight
end

--[[---------------------------------------------------------
	- func: GetBoxWidth()
	- desc: gets the object's switch width
--]]---------------------------------------------------------
function newobject:GetBoxWidth()
	return self.boxwidth
end

--[[---------------------------------------------------------
	- func: GetBoxHeight()
	- desc: gets the object's switch height
--]]---------------------------------------------------------
function newobject:GetBoxHeight()
	return self.boxheight
end

--[[---------------------------------------------------------
	- func: SetEnabled(bool)
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
	- desc: gets whether or not the object is currently down
--]]---------------------------------------------------------
function newobject:GetDown()
	return self.down
end

---------- module end ----------
end
