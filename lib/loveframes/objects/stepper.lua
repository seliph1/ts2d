return function(loveframes)
	---------- module start ----------

	local numbutton = loveframes.NewObject("stepper_button", "loveframes_object_stepper_button", true)

	function numbutton:initialize()
		self.type = "stepper_button"
		self.image = nil
		self.down = false
		self.hover = false

		self.Draw = function(self)
			local x, y = self.x, self.y
			local w, h = self.width, self.height
			local hover = self.hover
			local down = self.down
			local skin = loveframes.GetActiveSkin()
			local bodycolor = skin.controls.button_nohover_color
			if down then
				bodycolor = skin.controls.button_down_color
			elseif hover then
				bodycolor = skin.controls.button_hover_color
			end
			love.graphics.setColor(bodycolor)
			love.graphics.rectangle("fill", x, y, w, h)
			love.graphics.setColor(skin.controls.button_border_enabled_color or { 0, 0, 0, 1 })
			skin.OutlinedRectangle(x, y, w, h, false, false, false, false)
			if self.image then
				local iw, ih = self.image:getDimensions()
				local ix = x + w / 2 - iw / 2
				local iy = y + h / 2 - ih / 2
				if down then
					ix = ix + 1
					iy = iy + 1
				end
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(self.image, math.floor(ix), math.floor(iy))
			end
		end
	end

	function numbutton:SetImage(img)
		self.image = img
	end

	function numbutton:mousepressed(x, y, button)
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

	local newobject = loveframes.NewObject("stepper", "loveframes_object_stepper", true)

	function newobject:initialize()
		self.type = "stepper"
		self.width = 100
		self.height = 30
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
		self.vertical = false
		self.internals = {}
		self.OnValueChanged = nil

		local skin = loveframes.GetActiveSkin()
		local rightarrow = skin.images["arrow-right.png"]
		local leftarrow = skin.images["arrow-left.png"]

		local input = loveframes.objects["textbox"]:new()
		local increasebutton = loveframes.objects["stepper_button"]:new()
		local decreasesbutton = loveframes.objects["stepper_button"]:new()

		table.insert(self.internals, input)
		table.insert(self.internals, increasebutton)
		table.insert(self.internals, decreasesbutton)

		input.parent = self
		input:SetUsable({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ".", "-" })
		input:SetPadding(0, 0)
		input:SetAlignment("center")
		input:SetVerticalAlignment("center")
		input:SetText(self.value)
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

		increasebutton.parent = self
		increasebutton:SetImage(rightarrow)
		increasebutton.OnClick = function()
			local canmodify = self.canmodify
			if not canmodify then
				self:ModifyValue("add")
			else
				self.canmodify = false
			end
		end
		increasebutton.Update = function(object)
			local time = love.timer.getTime()
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

		decreasesbutton.parent = self
		decreasesbutton:SetImage(leftarrow)
		decreasesbutton.OnClick = function()
			local canmodify = self.canmodify
			if not canmodify then
				self:ModifyValue("subtract")
			else
				self.canmodify = false
			end
		end
		decreasesbutton.Update = function(object)
			local time = love.timer.getTime()
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

	function newobject:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		local internals = self.internals
		local parent = self.parent
		local base = loveframes.base
		local update = self.Update

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

	function newobject:GetValue()
		return self.value
	end

	function newobject:SetStepAmount(amount)
		self.increaseamount = amount
		self.decreaseamount = amount
		return self
	end

	function newobject:SetIncreaseAmount(amount)
		self.increaseamount = amount
		return self
	end

	function newobject:GetIncreaseAmount()
		return self.increaseamount
	end

	function newobject:SetDecreaseAmount(amount)
		self.decreaseamount = amount
		return self
	end

	function newobject:GetDecreaseAmount()
		return self.decreaseamount
	end

	function newobject:SetMax(max)
		local internals = self.internals
		local input = internals[1]
		local onvaluechanged = self.OnValueChanged
		self.max = max
		if self.value > max then
			self.value = max
			input:SetValue(max)
			if onvaluechanged then
				onvaluechanged(self, max)
			end
		end
		return self
	end

	function newobject:GetMax()
		return self.max
	end

	function newobject:SetMin(min)
		local internals = self.internals
		local input = internals[1]
		local onvaluechanged = self.OnValueChanged
		self.min = min
		if self.value < min then
			self.value = min
			input:SetValue(min)
			if onvaluechanged then
				onvaluechanged(self, min)
			end
		end
		return self
	end

	function newobject:GetMin()
		return self.min
	end

	function newobject:SetMinMax(min, max)
		local internals = self.internals
		local input = internals[1]
		local onvaluechanged = self.OnValueChanged
		self.min = min
		self.max = max
		if self.value > max then
			self.value = max
			input:SetValue(max)
			if onvaluechanged then
				onvaluechanged(self, max)
			end
		end
		if self.value < min then
			self.value = min
			input:SetValue(min)
			if onvaluechanged then
				onvaluechanged(self, min)
			end
		end
		return self
	end

	function newobject:GetMinMax()
		return self.min, self.max
	end

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

	function newobject:SetDecimals(decimals)
		self.decimals = decimals
		return self
	end

	function newobject:GetDecimals()
		return self.decimals
	end

	function newobject:SetFont(font)
		self.internals[1].font = font
		self.internals[1].field:setFont(font)
		return self
	end

	function newobject:GetFont()
		return self.internals[1].font
	end

	function newobject:SetVertical(bool)
		self.vertical = bool

		local skin = loveframes.GetActiveSkin()
		local increasebutton = self.internals[2]
		local decreasesbutton = self.internals[3]

		if bool then
			increasebutton:SetImage(skin.images["arrow-up.png"])
			decreasesbutton:SetImage(skin.images["arrow-down.png"])
		else
			increasebutton:SetImage(skin.images["arrow-right.png"])
			decreasesbutton:SetImage(skin.images["arrow-left.png"])
		end

		self:RedoLayout()
		return self
	end

	function newobject:GetVertical()
		return self.vertical
	end

	function newobject:RedoLayout()
		local input, increasebutton, decreasesbutton = self.internals[1], self.internals[2], self.internals[3]

		if self.vertical then
			local btn_size = self.width
			increasebutton:SetPos(0, 0)
			increasebutton:SetSize(self.width, btn_size)

			decreasesbutton:SetPos(0, self.height - btn_size)
			decreasesbutton:SetSize(self.width, btn_size)

			input:SetPos(0, btn_size)
			input:SetSize(self.width, self.height - (btn_size * 2))
		else
			local btn_size = self.height
			decreasesbutton:SetPos(0, 0)
			decreasesbutton:SetSize(btn_size, self.height)

			increasebutton:SetPos(self.width - btn_size, 0)
			increasebutton:SetSize(btn_size, self.height)

			input:SetPos(btn_size, 0)
			input:SetSize(self.width - (btn_size * 2), self.height)
		end
	end

	---------- module end ----------
	return newobject
end
