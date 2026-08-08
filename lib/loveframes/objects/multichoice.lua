--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- multichoice object
	local newobject = loveframes.NewObject("multichoice", "loveframes_object_multichoice", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function newobject:initialize()
		self.type = "multichoice"
		self.choice = ""
		self.text = "Select an option"
		self.width = 200
		self.height = 25
		self.listpadding = 0
		self.listspacing = 0
		self.buttonscrollamount = 1
		self.mousewheelscrollamount = 1
		self.sortfunc = function(a, b) return a < b end
		self.haslist = false
		self.dtscrolling = true
		self.enabled = true
		self.internal = false
		self.choices = {}
		self.internals = {}
		self.listheight = nil

		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]] ---------------------------------------------------------
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

		for index, internal in ipairs(self.internals) do
			internal:update()
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
		local list = self.internals[1]
		local hover = self.hover
		local enabled = self.enabled

		if hover and not list and enabled and button == 1 then
			self:MoveToTop()
			local baseparent = self:GetBaseParent()
			if baseparent and baseparent.type == "frame" then
				baseparent:MakeTop()
			end
			self.internals[1] = loveframes.objects["multichoicelist"]:new(self)
			return
		end

		if list then
			list:mousepressed(x, y, button)
		end
	end

	function newobject:mousereleased(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		local list = self.internals[1]
		if list then
			list:mousereleased(x, y, button)
		end
	end

	--[[---------------------------------------------------------
	- func: AddChoice(choice)
	- desc: adds a choice to the current list of choices
--]] ---------------------------------------------------------
	function newobject:AddChoice(choice)
		local choices = self.choices
		table.insert(choices, choice)

		return self
	end

	--[[---------------------------------------------------------
	- func: RemoveChoice(choice)
	- desc: removes the specified choice from the object's
			list of choices
--]] ---------------------------------------------------------
	function newobject:RemoveChoice(choice)
		local choices = self.choices

		for k, v in ipairs(choices) do
			if v == choice then
				table.remove(choices, k)
				break
			end
		end

		return self
	end

	--[[---------------------------------------------------------
	- func: SetChoice(choice)
	- desc: sets the current choice
--]] ---------------------------------------------------------
	function newobject:SetChoice(choice)
		self.choice = choice
		return self
	end

	--[[---------------------------------------------------------
	- func: SelectChoice(choice)
	- desc: selects a choice
--]] ---------------------------------------------------------
	function newobject:SelectChoice(choice)
		local onchoiceselected = self.OnChoiceSelected
		local list = self.internals[1]
		self.choice = choice

		if list then
			list:Close()
		end

		if onchoiceselected then
			onchoiceselected(self, choice)
		end

		return self
	end

	--[[---------------------------------------------------------
	- func: SetListHeight(height)
	- desc: sets the height of the list of choices
--]] ---------------------------------------------------------
	function newobject:SetListHeight(height)
		self.listheight = height
		return self
	end

	--[[---------------------------------------------------------
	- func: SetPadding(padding)
	- desc: sets the padding of the list of choices
--]] ---------------------------------------------------------
	function newobject:SetPadding(padding)
		self.listpadding = padding
		return self
	end

	--[[---------------------------------------------------------
	- func: SetSpacing(spacing)
	- desc: sets the spacing of the list of choices
--]] ---------------------------------------------------------
	function newobject:SetSpacing(spacing)
		self.listspacing = spacing
		return self
	end

	--[[---------------------------------------------------------
	- func: GetValue()
	- desc: gets the value (choice) of the object
--]] ---------------------------------------------------------
	function newobject:GetValue()
		return self.choice
	end

	--[[---------------------------------------------------------
	- func: GetChoice()
	- desc: gets the current choice (same as get value)
--]] ---------------------------------------------------------
	function newobject:GetChoice()
		return self.choice
	end

	--[[---------------------------------------------------------
	- func: SetText(text)
	- desc: sets the object's text
--]] ---------------------------------------------------------
	function newobject:SetText(text)
		self.text = text
		return self
	end

	--[[---------------------------------------------------------
	- func: GetText()
	- desc: gets the object's text
--]] ---------------------------------------------------------
	function newobject:GetText()
		return self.text
	end

	--[[---------------------------------------------------------
	- func: SetButtonScrollAmount(speed)
	- desc: sets the scroll amount of the object's scrollbar
			buttons
--]] ---------------------------------------------------------
	function newobject:SetButtonScrollAmount(amount)
		self.buttonscrollamount = amount
		return self
	end

	--[[---------------------------------------------------------
	- func: GetButtonScrollAmount()
	- desc: gets the scroll amount of the object's scrollbar
			buttons
--]] ---------------------------------------------------------
	function newobject:GetButtonScrollAmount()
		return self.buttonscrollamount
	end

	--[[---------------------------------------------------------
	- func: SetMouseWheelScrollAmount(amount)
	- desc: sets the scroll amount of the mouse wheel
--]] ---------------------------------------------------------
	function newobject:SetMouseWheelScrollAmount(amount)
		self.mousewheelscrollamount = amount
		return self
	end

	--[[---------------------------------------------------------
	- func: GetMouseWheelScrollAmount()
	- desc: gets the scroll amount of the mouse wheel
--]] ---------------------------------------------------------
	function newobject:GetMouseWheelScrollAmount()
		return self.mousewheelscrollamount
	end

	--[[---------------------------------------------------------
	- func: SetDTScrolling(bool)
	- desc: sets whether or not the object should use delta
			time when scrolling
--]] ---------------------------------------------------------
	function newobject:SetDTScrolling(bool)
		self.dtscrolling = bool
		return self
	end

	--[[---------------------------------------------------------
	- func: GetDTScrolling()
	- desc: gets whether or not the object should use delta
			time when scrolling
--]] ---------------------------------------------------------
	function newobject:GetDTScrolling()
		return self.dtscrolling
	end

	--[[---------------------------------------------------------
	- func: Sort(func)
	- desc: sorts the object's choices
--]] ---------------------------------------------------------
	function newobject:Sort(func)
		local default = self.sortfunc
		if func then
			table.sort(self.choices, func)
		else
			table.sort(self.choices, default)
		end
		return self
	end

	--[[---------------------------------------------------------
	- func: SetSortFunction(func)
	- desc: sets the object's default sort function
--]] ---------------------------------------------------------
	function newobject:SetSortFunction(func)
		self.sortfunc = func
		return self
	end

	--[[---------------------------------------------------------
	- func: GetSortFunction(func)
	- desc: gets the object's default sort function
--]] ---------------------------------------------------------
	function newobject:GetSortFunction()
		return self.sortfunc
	end

	--[[---------------------------------------------------------
	- func: Clear()
	- desc: removes all choices from the object's list
			of choices
--]] ---------------------------------------------------------
	function newobject:Clear()
		self.choices = {}
		self.choice = ""
		self.text = "Select an option"

		return self
	end

	--[[---------------------------------------------------------
	- func: SetClickable(bool)
	- desc: sets whether or not the object is enabled
--]] ---------------------------------------------------------
	function newobject:SetEnabled(bool)
		self.enabled = bool
		return self
	end

	--[[---------------------------------------------------------
	- func: GetEnabled()
	- desc: gets whether or not the object is enabled
--]] ---------------------------------------------------------
	function newobject:GetEnabled()
		return self.enabled
	end

	---------- module end ----------
end
