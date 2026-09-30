--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- tabbutton class
	local newobject = loveframes.NewObject("tabbutton", "loveframes_object_tabbutton", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function newobject:initialize(parent, text, tabnumber, image, onopened, onclosed)
		self.type = "tabbutton"
		self.font = loveframes.smallfont
		self.text = text
		self.tabnumber = tabnumber
		self.parent = parent
		self.state = parent.state
		self.staticx = 0
		self.navigable = true
		self.staticy = 0
		self.width = 50
		self.height = 25
		self.internal = true
		self.down = false
		self.image = nil
		self.OnOpened = nil
		self.OnClosed = nil

		if image then
			self:SetImage(image)
		end

		if onopened then
			self.OnOpened = onopened
		end

		if onclosed then
			self.OnClosed = onclosed
		end

		-- apply template properties to the object
		loveframes.ApplyTemplatesToObject(self)
		self:SetDrawFunc()

		self:RedoLayout()
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]] ---------------------------------------------------------
	function newobject:update(dt)
		local visible = self.visible
		local alwaysupdate = self.alwaysupdate

		if not visible then
			if not alwaysupdate then
				return
			end
		end

		local parent = self.parent
		local update = self.Update

		self:CheckHover()
		self:SetClickBounds(parent.x, parent.y, parent.width, parent.height)

		if update then
			update(self, dt)
		end
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: called when the player presses a mouse button
--]] ---------------------------------------------------------
	function newobject:mousepressed(x, y, button)
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
--]] ---------------------------------------------------------
	function newobject:mousereleased(x, y, button)
		local visible = self.visible
		if not visible then
			return
		end

		local hover = self.hover
		local parent = self.parent
		local tabnumber = self.tabnumber

		if hover and button == 1 then
			if button == 1 then
				local tab = parent.tab
				local internals = parent.internals
				local onopened = self.OnOpened
				local prevtab = internals[tab]
				local onclosed = prevtab.OnClosed
				parent:SwitchToTab(tabnumber)
				if onopened then
					onopened(self)
				end
				if onclosed then
					onclosed(prevtab)
				end
			end
		end

		self.down = false
	end

	--[[---------------------------------------------------------
	- func: SetText(text)
	- desc: sets the object's text
--]] ---------------------------------------------------------
	function newobject:SetText(text)
		self.text = text
		self:RedoLayout()
	end

	--[[---------------------------------------------------------
	- func: GetText()
	- desc: gets the object's text
--]] ---------------------------------------------------------
	function newobject:GetText()
		return self.text
	end

	--[[---------------------------------------------------------
	- func: SetImage(image)
	- desc: adds an image to the object
--]] ---------------------------------------------------------
	function newobject:SetImage(image)
		local parent = self.parent
		if type(image) == "string" then
			self.image = love.graphics.newImage(image)
			self.image:setFilter("nearest", "nearest")
		else
			self.image = image
		end
		self:RedoLayout()
	end

	--[[---------------------------------------------------------
	- func: GetImage()
	- desc: gets the object's image
--]] ---------------------------------------------------------
	function newobject:GetImage()
		return self.image
	end

	--[[---------------------------------------------------------
	- func: GetTabNumber()
	- desc: gets the object's tab number
--]] ---------------------------------------------------------
	function newobject:GetTabNumber()
		return self.tabnumber
	end

	function newobject:RedoLayout()
		local skin = loveframes.GetActiveSkin()
		local font = skin.controls.tab_text_font
		local parent = self.parent
		local text = self.text
		local image = self.image

		local width_sum = parent.tabmargin

		if text then
			width_sum = width_sum + font:getWidth(text) + parent.tabmargin
		end
		if image then
			local scale = 1
			local imagewidth, imageheight = image:getDimensions()
			if imageheight > (parent.tabheight - parent.tabmargin) then
				scale = (parent.tabheight - parent.tabmargin) / imageheight
			end

			width_sum = width_sum + math.floor(imagewidth * scale) + parent.tabmargin
		end

		self.width = math.max(width_sum, parent.minwidth)
		self.height = parent.tabheight
	end

	---------- module end ----------
end
