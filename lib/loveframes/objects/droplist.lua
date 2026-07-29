--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- panel object
	local newobject = loveframes.NewObject("droplist", "loveframes_object_droplist", true)

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------

	function newobject:initialize()
		-- Font properties
		local skin = loveframes.GetActiveSkin()
		local font = skin.directives.text_default_font or loveframes.basicfont
		--local color = skin.directives.text_default_color
		local color

		self.type = "droplist"
		self.width = 200
		self.height = 50
		self.internal = false
		self.children = {}
		self.elements = {}
		self.internals = {}
		self.padding = 5
		self.selected = 0
		self.hovered = 0
		self.zebra_list = false
		self.highlight = 0
		self.background = nil
		self.font = font
		self.texthash = love.graphics.newTextBatch(font)
		self.defaultcolor = color or { 1, 1, 1, 1 }
		self:SetDrawFunc()
		self.odd_list = love.graphics.newMesh(1, "fan")
		self.even_list = love.graphics.newMesh(1, "fan")
		self.cursor = loveframes.cursors.hand
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the element
--]] ---------------------------------------------------------
	function newobject:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		local children = self.children
		local parent = self.parent
		local base = loveframes.base
		local update = self.Update
		-- move to parent if there is a parent
		if parent ~= base then
			self.x = self.parent.x + self.staticx
			self.y = self.parent.y + self.staticy
		end
		--self:SetClickBounds(0,0, 32, 32)
		self:CheckHover()
		for k, v in ipairs(children) do
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
	function newobject:mousemoved(x, y, dx, dy, istouch)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		-- If object isn't being hovered, dont calculate
		if not (self.hover) then
			self.hovered = 0
			return
		end
		-- Retrieve the cell size
		local cell_x = self.width
		local cell_y = self.font:getHeight() + self.padding

		-- Get the relative position from mouse
		local rel_x = x - self.x
		local rel_y = y - self.y

		-- Check which cell is selected
		-- Ceil is used so it always return element id >= 1
		local element_id = math.min(math.ceil(rel_y / cell_y), #self.elements)

		if self.hovered ~= element_id then
			local onhover = self.OnHover
			if onhover then
				onhover(self, self.elements[element_id], element_id)
			end
		end

		self.hovered = element_id
	end

	function newobject:mousepressed(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		if not self.hover then
			-- Dont select, but dont deselect also
			return
		end

		-- Retrieve the cell size
		local cell_x = self.width
		local cell_y = self.font:getHeight() + self.padding

		-- Get the relative position from mouse
		local rel_x = x - self.x
		local rel_y = y - self.y

		-- Chech which cell is selected
		-- Ceil is used so it always return element id >= 1
		local element_id = math.ceil(rel_y / cell_y)
		if element_id < 0 or element_id > #self.elements then
			element_id = 0
		end

		if element_id ~= 0 and button == 1 then
			local onclick = self.OnClick
			if onclick then
				onclick(self, self.elements[element_id], element_id)
			end
		end
		self.selected = element_id
	end

	--[[---------------------------------------------------------
	- func: mousereleased(x, y, button)
	- desc: called when the player releases a mouse button
--]] ---------------------------------------------------------
	function newobject:mousereleased(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
	end

	--[[---------------------------------------------------------
	- func: wheelmoved(x, y)
	- desc: called when the player moves a mouse wheel
--]] ---------------------------------------------------------
	function newobject:wheelmoved(x, y)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		if not self.hover then return end
		for _, v in ipairs(self.internals) do
			v:wheelmoved(x, y)
		end
	end

	--[[---------------------------------------------------------
	- func: AddElement()
	- desc: add an element into the list
--]] ---------------------------------------------------------
	function newobject:AddElement(item, icon, append)
		local data = {}
		if type(item) == "string" then
			data.text = item
			if type(icon) == "string" or ((type(icon) == "userdata" or type(icon) == "table") and icon.getDimensions) then
				data.icon = icon
			elseif type(icon) == "boolean" then
				append = icon
			end
		elseif type(item) == "table" then
			if item.text then
				data.text = item.text
				if type(item.icon) == "string" or ((type(item.icon) == "userdata" or type(item.icon) == "table") and item.icon.getDimensions) then
					data.icon = item.icon
				end
			else
				self:AddElementsFromTable(item)
				return
			end
		end

		if type(data.icon) == "string" then
			local path = data.icon
			data.icon = love.graphics.newImage(path)
			data.icon:setFilter("nearest", "nearest")
		end

		table.insert(self.elements, data)
		if append then
			self:AppendElement(data)
		else
			self:ParseElements()
		end
	end

	newobject.AddItem = newobject.AddElement

	function newobject:AddElementsFromTable(tbl)
		local validElements = 0
		for _, item in ipairs(tbl) do
			if type(item) == "string" then
				table.insert(self.elements, { text = item })
				validElements = validElements + 1
			elseif type(item) == "table" and item.text then
				local data = { text = item.text, icon = item.icon }
				if type(data.icon) == "string" then
					local path = data.icon
					data.icon = love.graphics.newImage(path)
					data.icon:setFilter("nearest", "nearest")
				elseif type(data.icon) ~= "string" and not ((type(data.icon) == "userdata" or type(data.icon) == "table") and data.icon.getDimensions) then
					data.icon = nil
				end
				table.insert(self.elements, data)
				validElements = validElements + 1
			end
		end
		if validElements > 0 then
			self:ParseElements()
		end
	end

	newobject.AddItemsFromTable = newobject.AddElementsFromTable

	function newobject:RemoveElement(item)
		if item == nil then
			self.elements[#self.elements] = nil
			self:ParseElements()
		end

		if type(item) == "number" then
			if self.elements[item] then
				table.remove(self.elements, item)
				self:ParseElements()
			end
		end
	end

	newobject.RemoveItem = newobject.RemoveElement
	function newobject:GetElements()
		return self.elements
	end

	function newobject:Count()
		return #self.elements
	end

	newobject.ElementAmount = newobject.Count
	newobject.NumberOfElements = newobject.Count

	function newobject:Clear()
		self.elements = {}
		self.selected = 0
		self.hovered = 0
		self.odd_list = love.graphics.newMesh(1, "fan")
		self.even_list = love.graphics.newMesh(1, "fan")
		self:ParseElements()
	end

	--[[---------------------------------------------------------
	- func: ParseElements
	- desc: put the elements into a list
--]] ---------------------------------------------------------
	function newobject:fixUTF8(s, replacement)
		local p, len, invalid = 1, #s, {}
		while p <= len do
			if p == s:find("[%z\1-\127]", p) then
				p = p + 1
			elseif p == s:find("[\194-\223][\128-\191]", p) then
				p = p + 2
			elseif p == s:find("\224[\160-\191][\128-\191]", p)
				or p == s:find("[\225-\236][\128-\191][\128-\191]", p)
				or p == s:find("\237[\128-\159][\128-\191]", p)
				or p == s:find("[\238-\239][\128-\191][\128-\191]", p) then
				p = p + 3
			elseif p == s:find("\240[\144-\191][\128-\191][\128-\191]", p)
				or p == s:find("[\241-\243][\128-\191][\128-\191][\128-\191]", p)
				or p == s:find("\244[\128-\143][\128-\191][\128-\191]", p) then
				p = p + 4
			else
				s = s:sub(1, p - 1) .. replacement .. s:sub(p + 1)
				table.insert(invalid, p)
			end
		end
		return s, invalid
	end

	function newobject:ParseText(str)
		local formattedchunks = {}
		local formattedstring = {}
		local defaultColor = self.defaultcolor

		if not str:find("©") then
			return { defaultColor, str }, str
		end

		for leading, capture in string.gmatch(str, "(.-)©([^©]+)") do
			if leading then
				table.insert(formattedchunks, defaultColor)
				table.insert(formattedchunks, leading)
				table.insert(formattedstring, leading)
			end
			local r, g, b = string.match(capture, "(%d%d%d)(%d%d%d)(%d%d%d)")
			local text = string.sub(capture, 10, -1)
			if r and g and b then
				table.insert(formattedchunks,
					{ tonumber(r) / 255, tonumber(g) / 255, tonumber(b) / 255 }
				)
				table.insert(formattedchunks, text)
				table.insert(formattedstring, text)
			else
				text = "©" .. capture
			end
		end

		return formattedchunks, table.concat(formattedstring)
	end

	function newobject:ParseElements(filter)
		self.texthash:clear()
		local elements = self.elements
		local maxwidth = 0
		local fontheight = self.font:getHeight()
		for index, value in ipairs(elements) do
			local parsedvalue = ""
			local text = type(value) == "table" and value.text or value
			-- Fix the text
			text = self:fixUTF8(text, " ")

			-- Parse the obtained string with cs2d formatting
			local text_parsed_colors
			text_parsed_colors, parsedvalue = self:ParseText(text)

			-- Calculate height position of the line
			local height = (index - 1) * (fontheight + self.padding)

			-- Calculate total wideness of the line
			local width = self.font:getWidth(parsedvalue)

			-- Resize the max width to update the layout
			local x_offset = (type(value) == "table" and value.icon) and 24 or 5
			if width + x_offset > maxwidth then
				maxwidth = width + x_offset
			end

			-- Add the fixed, formatted text to the texthash
			self.texthash:add(text_parsed_colors, x_offset, height + self.padding / 2)
		end

		-- Resize the structure to accomodate new elements in scroll body
		if maxwidth > self.width then
			self:SetSize(maxwidth, math.max(50, (fontheight + self.padding) * #elements))
		else
			self:SetSize(self.width, math.max(50, (fontheight + self.padding) * #elements))
		end

		-- Create the alternating list rectangle mesh background
		self:createBackgroundMesh(elements, 0, 0, self.width, fontheight + self.padding)
	end

	function newobject:AppendElement(value)
		local elements = self.elements
		local maxwidth = 0
		local fontheight = self.font:getHeight()

		local parsedvalue = ""
		local text = type(value) == "table" and value.text or value
		-- Fix the text
		text = self:fixUTF8(text, " ")

		-- Parse the obtained string with cs2d formatting
		local text_parsed_colors
		text_parsed_colors, parsedvalue = self:ParseText(text)

		-- Calculate height position of the line
		local height = (#self.elements - 1) * (fontheight + self.padding)

		-- Calculate total wideness of the line
		local width = self.font:getWidth(parsedvalue)

		-- Resize the max width to update the layout
		local x_offset = (type(value) == "table" and value.icon) and 24 or 5
		if width + x_offset > maxwidth then
			maxwidth = width + x_offset
		end
		-- Add the fixed, formatted text to the texthash
		self.texthash:add(text_parsed_colors, x_offset, height + self.padding / 2)

		-- Resize the structure to accomodate new elements in scroll body
		if maxwidth > self.width then
			self:SetSize(maxwidth, math.max(50, (fontheight + self.padding) * #elements))
		else
			self:SetSize(self.width, math.max(50, (fontheight + self.padding) * #elements))
		end

		-- Create the alternating list rectangle mesh background
		self:createBackgroundMesh(elements, 0, 0, self.width, fontheight + self.padding)
	end

	function newobject:RedoLayout()
		local elements = self.elements
		local fontheight = self.font:getHeight()
		-- Create the alternating list rectangle mesh background
		self:createBackgroundMesh(elements, 0, 0, self.width, fontheight + self.padding)
	end

	function newobject:createBackgroundMesh(list, x, y, width, height)
		local oddVertices = {}
		local evenVertices = {}
		local r, g, b = 1, 1, 1
		for i = 1, #list do
			local vertices = oddVertices
			-- Alterna os vertices de 2 em 2
			if i % 2 == 0 then vertices = evenVertices end
			local topY = y + (i - 1) * height
			-- Cada retângulo são 2 triângulos (6 vértices)
			-- A ordem é (x,y,u,v,r,g,b,a)
			-- u,v não serão usados (0,0)
			-- triangulo 1
			table.insert(vertices, { x, topY, 0, 0, r, g, b, 1 })
			table.insert(vertices, { x + width, topY, 0, 0, r, g, b, 1 })
			table.insert(vertices, { x + width, topY + height, 0, 0, r, g, b, 1 })
			-- triangulo 2
			table.insert(vertices, { x, topY, 0, 0, r, g, b, 1 })
			table.insert(vertices, { x + width, topY + height, 0, 0, r, g, b, 1 })
			table.insert(vertices, { x, topY + height, 0, 0, r, g, b, 1 })
		end
		if #oddVertices > 1 then
			self.odd_list = love.graphics.newMesh(oddVertices, "triangles", "static")
		end
		if #evenVertices > 1 then
			self.even_list = love.graphics.newMesh(evenVertices, "triangles", "static")
		end
	end

	--[[---------------------------------------------------------
	- func: SetFont
	- desc: set the object's font
--]] ---------------------------------------------------------
	function newobject:SetFont(font)
		self.texthash:setFont(font)
		self.font = font
		self:ParseElements()
		return self
	end

	function newobject:SetBackground(r, g, b, a)
		assert(type(r) == "table" or (type(r) == "number" and type(b) == "number" and type(g) == "number"))
		if type(r) == "table" then
			self.background = r
		elseif type(r) == "number" then
			self.background = { r, g, b, a }
		end
		return self
	end

	function newobject:RemoveBackground()
		self.background = nil
		return self
	end

	function newobject:GetFont()
		local font = self.font
		return font
	end

	function newobject:SetPadding(padding)
		self.padding = padding
		self:ParseElements()
		return self
	end

	function newobject:GetPadding()
		local padding = self.padding
		return padding
	end

	function newobject:SetZebra(bool)
		self.zebra_list = bool
		return self
	end

	function newobject:SetHighlight(bool)
		self.highlight = bool
		return self
	end

	function newobject:Sort(f)
		if not f then
			f = function(a, b)
				return a:lower() < b:lower()
			end
		end
		table.sort(self.elements, f)
		self:ParseElements()
	end

	function newobject:SetFilter(filter)
		self.filter = filter
		self:ParseElements(filter)
		return self
	end

	---------- module end ----------
end
