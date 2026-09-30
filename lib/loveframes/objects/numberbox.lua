--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	local numbutton = loveframes.NewObject("numberbox_button", "loveframes_object_numberbox_button", true)

	function numbutton:initialize()
		self.type = "numberbox_button"
		self.image = nil
		self.down = false
		self.hover = false

		local skin = loveframes.GetActiveSkin()
		self.Draw = function(self)
			local x, y = self.x, self.y
			local w, h = self.width, self.height
			local hover = self.hover
			local down = self.down
			local skin = loveframes.GetActiveSkin()
			local bodycolor = skin.controls.button_nohover_color
			local enabled = true
			if self.parent and self.parent.enabled == false then enabled = false end

			if enabled then
				if down then
					bodycolor = skin.controls.button_down_color
				elseif hover then
					bodycolor = skin.controls.button_hover_color
				end
			else
				bodycolor = skin.controls.button_disabled_color
			end
			love.graphics.setColor(bodycolor)
			love.graphics.rectangle("fill", x, y, w, h)

			if enabled then
				love.graphics.setColor(skin.controls.button_border_enabled_color)
			else
				love.graphics.setColor(skin.controls.button_border_disabled_color)
			end
			skin.OutlinedRectangle(x, y, w, h, false, false, false, false)

			if self.image then
				local iw, ih = self.image:getDimensions()
				local ix = x + w / 2 - iw / 2
				local iy = y + h / 2 - ih / 2
				if down and enabled then
					ix = ix + 1
					iy = iy + 1
				end
				if enabled then
					love.graphics.setColor(1, 1, 1, 1)
				else
					love.graphics.setColor(1, 1, 1, 0.5)
				end
				love.graphics.draw(self.image, math.floor(ix), math.floor(iy))
			end
		end
	end

	function numbutton:SetImage(img)
		self.image = img
	end

	function numbutton:mousepressed(x, y, button)
		if self.parent and self.parent.enabled == false then return end
		if button == 1 and self.hover then
			self.down = true
		end
	end

	function numbutton:mousereleased(x, y, button)
		if button == 1 then
			if self.hover and self.down then
				if self.OnClick then self.OnClick() end
			end
			self.down = false
		end
	end

	function numbutton:update(dt)
		local parent = self.parent
		local base = loveframes.base
		if parent and parent ~= base then
			self.x = parent.x + (self.staticx or 0)
			self.y = parent.y + (self.staticy or 0)
		end
		self:CheckHover()
		if self.Update then self.Update(self, dt) end
	end

	-- numberbox object
	local newobject = loveframes.NewObject("numberbox", "loveframes_object_numberbox", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function newobject:initialize()
		self.type = "numberbox"
		self.width = 80
		self.height = 25
		self.value = 0
		self.increaseamount = 1
		self.decreaseamount = 1
		self.min = -100
		self.max = 100
		self.delay = 0
		self.decimals = 0
		self.internal = false
		self.canmodify = false
		self.lastbuttonclicked = false
		self.enabled = true
		self.internals = {}
		self.OnValueChanged = nil

		local skin = loveframes.GetActiveSkin()
		local uparrow = skin.images["arrow-up.png"]
		local downarrow = skin.images["arrow-down.png"]

		local input = loveframes.objects["textbox"]:new()
		local increasebutton = loveframes.objects["numberbox_button"]:new()
		local decreasesbutton = loveframes.objects["numberbox_button"]:new()

		table.insert(self.internals, input)
		table.insert(self.internals, increasebutton)
		table.insert(self.internals, decreasesbutton)

		input.parent = self
		input:SetUsable({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".", "-" })
		input:SetVerticalAlignment("center")
		input:SetText(self.value)
		local old_mousepressed = input.mousepressed
		input.mousepressed = function(obj, cx, cy, cbutton, cistouch, cpresses)
			if not self.enabled then return end
			if old_mousepressed then old_mousepressed(obj, cx, cy, cbutton, cistouch, cpresses) end
		end
		local old_keypressed = input.keypressed
		input.keypressed = function(obj, key, isrepeat)
			if not self.enabled then return end
			if old_keypressed then old_keypressed(obj, key, isrepeat) end
		end
		input.OnTextChanged = function(object)
			local value = self.value
			local newvalue = tonumber(object.field:getText())
			if not newvalue then
				self.value = value
				input:SetText(value)
				return
			end
			self.value = newvalue
			if self.value > self.max then
				self.value = self.max
				object:SetText(self.value)
			end
			if self.value < self.min then
				self.value = self.min
				object:SetText(self.value)
			end
			if value ~= self.value then
				if self.OnValueChanged then
					self.OnValueChanged(self, self.value)
				end
			end
		end

		-- Up arrow increase
		increasebutton.parent = self
		increasebutton:SetImage(uparrow)
		increasebutton.OnClick = function()
			local canmodify = self.canmodify
			if not canmodify then
				self:ModifyValue("add")
			else
				self.canmodify = false
			end
		end
		increasebutton.Update = function(object)
			local time = 0
			time = love.timer.getTime()
			local delay = self.delay
			local down = object.down
			local canmodify = self.canmodify
			local lastbuttonclicked = self.lastbuttonclicked

			if down and not canmodify then
				self:ModifyValue("add")
				self.canmodify = true
				self.delay = time + 0.80
				self.lastbuttonclicked = object
			elseif down and canmodify and delay < time then
				self:ModifyValue("add")
				self.delay = time + 0.02
			elseif not down and canmodify and lastbuttonclicked == object then
				self.canmodify = false
				self.delay = time + 0.80
			end
		end

		-- Down arrow decrease
		decreasesbutton.parent = self
		decreasesbutton:SetImage(downarrow)
		decreasesbutton.OnClick = function()
			local canmodify = self.canmodify
			if not canmodify then
				self:ModifyValue("subtract")
			else
				self.canmodify = false
			end
		end
		decreasesbutton.Update = function(object)
			local time = 0
			time = love.timer.getTime()
			local delay = self.delay
			local down = object.down
			local canmodify = self.canmodify
			local lastbuttonclicked = self.lastbuttonclicked

			if down and not canmodify then
				self:ModifyValue("subtract")
				self.canmodify = true
				self.delay = time + 0.80
				self.lastbuttonclicked = object
			elseif down and canmodify and delay < time then
				self:ModifyValue("subtract")
				self.delay = time + 0.02
			elseif not down and canmodify and lastbuttonclicked == object then
				self.canmodify = false
				self.delay = time + 0.80
			end
		end

		self:RedoLayout()
		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the element
--]] ---------------------------------------------------------
	function newobject:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		local internals = self.internals
		local parent = self.parent
		local base = loveframes.base
		local update = self.Update

		-- move to parent if there is a parent
		if parent ~= base then
			self.x = self.parent.x + self.staticx
			self.y = self.parent.y + self.staticy
		end
		self:CheckHover()
		for _, v in ipairs(internals) do
			v:update(dt)
		end
		if update then
			update(self, dt)
		end
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]] ---------------------------------------------------------
	function newobject:mousepressed(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		local internals = self.internals
		local hover = self.hover
		if hover and button == 1 then
			local baseparent = self:GetBaseParent()
			if baseparent and baseparent.type == "frame" then
				baseparent:MakeTop()
			end
		end
		for k, v in ipairs(internals) do
			v:mousepressed(x, y, button)
		end
	end

	--[[---------------------------------------------------------
	- func: SetValue(value)
	- desc: sets the object's value
--]] ---------------------------------------------------------
	function newobject:SetValue(value)
		local min = self.min
		local curvalue = self.value
		value = tonumber(value) or min
		local internals = self.internals
		local input = internals[1]
		local onvaluechanged = self.OnValueChanged
		self.value = value
		input:SetText(value)
		if value ~= curvalue and onvaluechanged then
			onvaluechanged(self, value)
		end
		return self
	end

	--[[---------------------------------------------------------
	- func: GetValue()
	- desc: gets the object's value
--]] ---------------------------------------------------------
	function newobject:GetValue()
		return self.value
	end

	--[[---------------------------------------------------------
	- func: SetIncreaseAmount(amount)
	- desc: sets the object's increase amount
--]] ---------------------------------------------------------
	function newobject:SetStepAmount(amount)
		self.increaseamount = amount
		self.decreaseamount = amount
		return self
	end

	--[[---------------------------------------------------------
	- func: SetIncreaseAmount(amount)
	- desc: sets the object's increase amount
--]] ---------------------------------------------------------
	function newobject:SetIncreaseAmount(amount)
		self.increaseamount = amount
		return self
	end

	--[[---------------------------------------------------------
	- func: GetIncreaseAmount()
	- desc: gets the object's increase amount
--]] ---------------------------------------------------------
	function newobject:GetIncreaseAmount()
		return self.increaseamount
	end

	--[[---------------------------------------------------------
	- func: SetDecreaseAmount(amount)
	- desc: sets the object's decrease amount
--]] ---------------------------------------------------------
	function newobject:SetDecreaseAmount(amount)
		self.decreaseamount = amount
		return self
	end

	--[[---------------------------------------------------------
	- func: GetDecreaseAmount()
	- desc: gets the object's decrease amount
--]] ---------------------------------------------------------
	function newobject:GetDecreaseAmount()
		return self.decreaseamount
	end

	--[[---------------------------------------------------------
	- func: SetMax(max)
	- desc: sets the object's maximum value
--]] ---------------------------------------------------------
	function newobject:SetMax(max)
		local internals = self.internals
		local input = internals[1]
		local onvaluechanged = self.OnValueChanged
		self.max = max
		if self.value > max then
			self.value = max
			input:SetText(max)
			if onvaluechanged then
				onvaluechanged(self, max)
			end
		end
		return self
	end

	--[[---------------------------------------------------------
	- func: GetMax()
	- desc: gets the object's maximum value
--]] ---------------------------------------------------------
	function newobject:GetMax()
		return self.max
	end

	--[[---------------------------------------------------------
	- func: SetMin(min)
	- desc: sets the object's minimum value
--]] ---------------------------------------------------------
	function newobject:SetMin(min)
		local internals = self.internals
		local input = internals[1]
		local onvaluechanged = self.OnValueChanged
		self.min = min
		if self.value < min then
			self.value = min
			input:SetText(min)
			if onvaluechanged then
				onvaluechanged(self, min)
			end
		end
		return self
	end

	--[[---------------------------------------------------------
	- func: GetMin()
	- desc: gets the object's minimum value
--]] ---------------------------------------------------------
	function newobject:GetMin()
		return self.min
	end

	--[[---------------------------------------------------------
	- func: SetMinMax()
	- desc: sets the object's minimum and maximum values
--]] ---------------------------------------------------------
	function newobject:SetMinMax(min, max)
		local internals = self.internals
		local input = internals[1]
		local onvaluechanged = self.OnValueChanged
		self.min = min
		self.max = max
		if self.value > max then
			self.value = max
			input:SetText(max)
			if onvaluechanged then
				onvaluechanged(self, max)
			end
		end
		if self.value < min then
			self.value = min
			print(input)
			input:SetText(min)
			if onvaluechanged then
				onvaluechanged(self, min)
			end
		end
		return self
	end

	--[[---------------------------------------------------------
	- func: GetMinMax()
	- desc: gets the object's minimum and maximum values
--]] ---------------------------------------------------------
	function newobject:GetMinMax()
		return self.min, self.max
	end

	--[[---------------------------------------------------------
	- func: ModifyValue(type)
	- desc: modifies the object's value
--]] ---------------------------------------------------------
	function newobject:ModifyValue(type)
		local value = self.value
		local internals = self.internals
		local input = internals[1]
		local decimals = self.decimals
		local onvaluechanged = self.OnValueChanged
		if not value then
			return
		end
		if type == "add" then
			local increaseamount = self.increaseamount
			local max = self.max
			self.value = value + increaseamount
			if self.value > max then
				self.value = max
			end
			self.value = loveframes.Round(self.value, decimals)
			input:SetText(self.value)
			if value ~= self.value then
				if onvaluechanged then
					onvaluechanged(self, self.value)
				end
			end
		elseif type == "subtract" then
			local decreaseamount = self.decreaseamount
			local min = self.min
			self.value = value - decreaseamount
			if self.value < min then
				self.value = min
			end
			self.value = loveframes.Round(self.value, decimals)
			input:SetText(self.value)
			if value ~= self.value then
				if onvaluechanged then
					onvaluechanged(self, self.value)
				end
			end
		end
		return self
	end

	--[[---------------------------------------------------------
	- func: SetDecimals(decimals)
	- desc: sets how many decimals the object's value
			can have
--]] ---------------------------------------------------------
	function newobject:SetDecimals(decimals)
		self.decimals = decimals
		return self
	end

	--[[---------------------------------------------------------
	- func: GetDecimals()
	- desc: gets how many decimals the object's value
			can have
--]] ---------------------------------------------------------
	function newobject:GetDecimals()
		return self.decimals
	end

	--[[---------------------------------------------------------
	- func: SetFont(font)/GetFont()
	- desc: sets/gets the object's font
--]] ---------------------------------------------------------
	function newobject:SetFont(font)
		self.internals[1].font = font
		self.internals[1].field:setFont(font)
		return self
	end

	function newobject:GetFont()
		return self.internals[1].font
	end

	--[[---------------------------------------------------------
	- func: SetPadding() SetHorizontalPadding() SetVerticalPadding()
	- desc: sets the object's padding
--]] ---------------------------------------------------------
	function newobject:SetPadding(padding)
		self.internals[1].verticalpadding = padding
		self.internals[1].horizontalpadding = padding

		self.internals[1].field:setDimensions(
			self.internals[1].width - math.max(padding * 2, 0),
			self.internals[1].height - math.max(padding * 2, 0)
		)
		return self
	end

	function newobject:SetVerticalPadding(padding)
		self.internals[1].verticalpadding = padding
		self.internals[1].field:setHeight(self.internals[1].height - math.max(padding * 2, 0))
		return self
	end

	function newobject:SetHorizontalPadding(padding)
		self.internals[1].horizontalpadding = padding
		self.internals[1].field:setWidth(self.internals[1].width - math.max(padding * 2, 0))
		return self
	end

	function newobject:RedoLayout()
		local input, increasebutton, decreasesbutton =
			self.internals[1], self.internals[2], self.internals[3]

		local width = 25
		increasebutton.width = width
		increasebutton.height = math.ceil(self.height / 2)
		decreasesbutton.width = width
		decreasesbutton.height = math.ceil(self.height / 2)
		increasebutton.staticx = self.width - width
		increasebutton.staticy = 0
		decreasesbutton.staticx = self.width - width
		decreasesbutton.staticy = math.floor(self.height / 2)

		input:SetSize(self.width - width, self.height)
	end

	--[[---------------------------------------------------------
	- func: GetPadding() GetVerticalPadding() GetHorizontalPadding()
	- desc: gets the object's padding
--]] ---------------------------------------------------------
	function newobject:GetPadding()
		return self.internals[1].verticalpadding, self.internals[1].horizontalpadding
	end

	function newobject:GetVerticalPadding()
		return self.internals[1].verticalpadding
	end

	function newobject:GetHorizontalPadding()
		return self.internals[1].horizontalpadding
	end

	function newobject:SetEnabled(bool)
		self.enabled = bool
		return self
	end

	function newobject:GetEnabled()
		return self.enabled
	end

	---------- module end ----------
end
