--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]]------------------------------------------------

return function(loveframes)
---------- module start ----------

-- menuoption object
local MenuOption = loveframes.NewObject("menuoption", "loveframes_object_menuoption", true)

--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]]---------------------------------------------------------
function MenuOption:initialize(parent, option_type, menu)
	local skin = self:GetSkin()
	local font = skin.controls.menuoption_text_font

	self.type = "menuoption"
	self.text = "Option"
	self.width = 100
	self.height = font:getHeight() or 25
	self.contentwidth = self.width
	self.contentheight = self.height
	self.parent = parent
	self.option_type = option_type or "option"
	self.menu = menu
	self.activated = false
	self.internal = true
	self.icon = false
	self.func = nil
	self.margin = 5
	self:SetDrawFunc()

	if option_type == "divider" then
		self.height = 5
	end
end

--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]]---------------------------------------------------------
function MenuOption:update(dt)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	self:CheckHover()
	local parent = self.parent
	local base = loveframes.base
	local update = self.Update

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
function MenuOption:mousepressed(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
end

--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]]---------------------------------------------------------
function MenuOption:mousereleased(x, y, button)
	if not self:OnState() then return end
	if not self:isUpdating() then return end
	local hover = self.hover
	local option_type = self.option_type
	if hover and option_type ~= "divider" and button == 1 then
		local func = self.func
		if func then
			local text = self.text
			func(self, text)
		end
		local basemenu = self.parent:GetBaseMenu()
		basemenu:Close()
	end
end

--[[---------------------------------------------------------
	- func: SetText(text)
	- desc: sets the object's text
--]]---------------------------------------------------------
function MenuOption:SetText(text)
	if self.option_type == "divider" then return self end

	local skin = self:GetSkin()
	local font = skin.controls.menuoption_text_font
	self.width = font:getWidth(text)
	self.height = font:getHeight() + self.margin*2
	self.contentwidth = self.width
	self.contentheight = self.height
	self.text = text

	if self.parentmenu and self.parentmenu.RedoLayout then
		self.parentmenu.RedoLayout()
	end

	return self
end

--[[---------------------------------------------------------
	- func: GetText()
	- desc: gets the object's text
--]]---------------------------------------------------------
function MenuOption:GetText()
	return self.text
end

--[[---------------------------------------------------------
	- func: SetIcon(icon)
	- desc: sets the object's icon
--]]---------------------------------------------------------
function MenuOption:SetIcon(icon)
	if self.option_type == "divider" then return self end

	if type(icon) == "string" then
		self.icon = love.graphics.newImage(icon)
		self.icon:setFilter("nearest", "nearest")
	elseif type(icon) == "userdata" then
		self.icon = icon
	end
end

--[[---------------------------------------------------------
	- func: GetIcon()
	- desc: gets the object's icon
--]]---------------------------------------------------------
function MenuOption:GetIcon()
	return self.icon
end

--[[---------------------------------------------------------
	- func: SetFunction(func)
	- desc: sets the object's function
--]]---------------------------------------------------------
function MenuOption:SetFunction(func)
	self.func = func
end

---------- module end ----------
end
