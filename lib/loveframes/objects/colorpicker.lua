--[[------------------------------------------------
	-- Love Frames - A GUI library for LOVE --
	-- Copyright (c) 2012-2014 Kenny Shields --
--]] ------------------------------------------------

return function(loveframes)
	---------- module start ----------

	-- colorpicker object
	local newobject = loveframes.NewObject("colorpicker", "loveframes_object_colorpicker", true)

	--[[---------------------------------------------------------
	Color Utility Functions
--]] ---------------------------------------------------------
	local function hsvToRgb(h, s, v)
		if s == 0 then
			return v, v, v
		end
		local i = math.floor(h * 6)
		local f = (h * 6) - i
		local p = v * (1 - s)
		local q = v * (1 - s * f)
		local t = v * (1 - s * (1 - f))
		i = i % 6
		if i == 0 then
			return v, t, p
		elseif i == 1 then
			return q, v, p
		elseif i == 2 then
			return p, v, t
		elseif i == 3 then
			return p, q, v
		elseif i == 4 then
			return t, p, v
		elseif i == 5 then
			return v, p, q
		end
	end

	local function rgbToHsv(r, g, b)
		local max = math.max(r, g, b)
		local min = math.min(r, g, b)
		local h, s, v
		v = max

		local d = max - min
		if max == 0 then
			s = 0
		else
			s = d / max
		end

		if max == min then
			h = 0
		else
			if max == r then
				h = (g - b) / d
				if g < b then h = h + 6 end
			elseif max == g then
				h = (b - r) / d + 2
			elseif max == b then
				h = (r - g) / d + 4
			end
			h = h / 6
		end

		return h, s, v
	end

	local function hexToRgba(hex)
		hex = hex:gsub("#", "")
		if #hex == 6 then
			local r = tonumber(hex:sub(1, 2), 16)
			local g = tonumber(hex:sub(3, 4), 16)
			local b = tonumber(hex:sub(5, 6), 16)
			if r and g and b then
				return r / 255, g / 255, b / 255, 1
			end
		elseif #hex == 8 then
			local r = tonumber(hex:sub(1, 2), 16)
			local g = tonumber(hex:sub(3, 4), 16)
			local b = tonumber(hex:sub(5, 6), 16)
			local a = tonumber(hex:sub(7, 8), 16)
			if r and g and b and a then
				return r / 255, g / 255, b / 255, a / 255
			end
		end
		return nil
	end

	local function rgbaToHex(r, g, b, a)
		local ir = math.floor(r * 255 + 0.5)
		local ig = math.floor(g * 255 + 0.5)
		local ib = math.floor(b * 255 + 0.5)
		local ia = math.floor(a * 255 + 0.5)
		return string.format("%02X%02X%02X%02X", ir, ig, ib, ia)
	end

	local function generateColorWheel(radius)
		local size = radius * 2
		local data = love.image.newImageData(size, size)
		local cx, cy = radius, radius
		for y = 0, size - 1 do
			for x = 0, size - 1 do
				local dx = x - cx
				local dy = y - cy
				local dist = math.sqrt(dx * dx + dy * dy)
				if dist <= radius then
					local theta = math.atan2(dy, dx)
					local h = (theta + math.pi) / (2 * math.pi)
					local s = dist / radius
					local r, g, b = hsvToRgb(h, s, 1)

					-- Edge anti-aliasing
					local alpha = 1
					if dist > radius - 1 then
						alpha = 1 - (dist - (radius - 1))
					end
					data:setPixel(x, y, r, g, b, alpha)
				else
					data:setPixel(x, y, 0, 0, 0, 0)
				end
			end
		end
		local img = love.graphics.newImage(data)
		data:release()
		return img
	end

	--[[---------------------------------------------------------
	- func: initialize()
	- desc: initializes the object
--]] ---------------------------------------------------------
	function newobject:initialize()
		self.type = "colorpicker"
		self.width = 330
		self.height = 135
		self.color = { 1, 1, 1, 1 }
		self.hsv = { 0, 0, 1 }
		self.internal = false
		self.internals = {}
		self.OnColorChanged = nil
		self.wheel_img = nil
		self.updating_gui = false

		-- 1. Captions for inputs
		self.wheel_lbl = loveframes.objects["label"]:new()
		self.wheel_lbl.parent = self
		self.wheel_lbl:SetText("Cor")
		table.insert(self.internals, self.wheel_lbl)

		self.v_lbl = loveframes.objects["label"]:new()
		self.v_lbl.parent = self
		self.v_lbl:SetText("V")
		table.insert(self.internals, self.v_lbl)

		self.a_lbl = loveframes.objects["label"]:new()
		self.a_lbl.parent = self
		self.a_lbl:SetText("A")
		table.insert(self.internals, self.a_lbl)

		-- 2. Color Wheel Panel (Hue & Saturation)
		local wheel = loveframes.objects["panel"]:new()
		wheel.parent = self
		wheel.dragging = false
		wheel.collide = true

		wheel.Draw = function(object)
			if object.drawfunc then
				object.drawfunc(object)
			end

			local x, y = object:GetPos()
			local w, h = object:GetSize()

			-- Draw the cached color wheel image
			if self.wheel_img then
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.draw(self.wheel_img, x, y)
			end

			-- Draw active color marker
			local R = w / 2
			local cx, cy = x + R, y + R
			local theta = self.hsv[1] * 2 * math.pi - math.pi
			local d = self.hsv[2] * R
			local mx = cx + d * math.cos(theta)
			local my = cy + d * math.sin(theta)

			-- Marker circle (contrasting colors)
			love.graphics.setColor(0, 0, 0, 1)
			love.graphics.circle("line", mx, my, 5)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.circle("line", mx, my, 4)
		end

		wheel.pickColor = function(object, mx, my)
			local ox, oy = object:GetPos()
			local ow, oh = object:GetSize()
			local cx, cy = ox + ow / 2, oy + oh / 2
			local dx = mx - cx
			local dy = my - cy
			local dist = math.sqrt(dx * dx + dy * dy)
			local R = ow / 2

			if dist > R then
				dx = (dx / dist) * R
				dy = (dy / dist) * R
				dist = R
			end

			local s = dist / R
			local theta = math.atan2(dy, dx)
			local h = (theta + math.pi) / (2 * math.pi)

			self.hsv[1] = h
			self.hsv[2] = s

			local r, g, b = hsvToRgb(h, s, self.hsv[3])
			self:SetColor(r, g, b, self.color[4], "wheel")
		end

		wheel.mousepressed = function(object, x, y, button)
			if button == 1 and object.hover then
				object.dragging = true
				loveframes.downobject = object
				object:pickColor(x, y)
			end
		end

		wheel.mousereleased = function(object, x, y, button)
			if button == 1 and object.dragging then
				object.dragging = false
				if loveframes.downobject == object then
					loveframes.downobject = false
				end
			end
		end

		wheel.Update = function(object, dt)
			if object.dragging then
				local mx, my = love.mouse.getPosition()
				object:pickColor(mx, my)
			end
		end

		self.wheel = wheel
		table.insert(self.internals, wheel)

		-- 3. Brightness Slider (Value)
		local v_slider = loveframes.objects["slider"]:new()
		v_slider.parent = self
		v_slider:SetSlideType("vertical")
		v_slider:SetMinMax(0, 100)
		v_slider:SetDecimals(0)
		v_slider:SetValue(100)
		self.v_slider = v_slider
		table.insert(self.internals, v_slider)

		-- 4. Alpha Slider (Alpha)
		local a_slider = loveframes.objects["slider"]:new()
		a_slider.parent = self
		a_slider:SetSlideType("vertical")
		a_slider:SetMinMax(0, 100)
		a_slider:SetDecimals(0)
		a_slider:SetValue(100)
		self.a_slider = a_slider
		table.insert(self.internals, a_slider)

		-- Update loop for sliders
		local function updateFromSliders()
			if self.updating_gui then return end
			local v = self.v_slider:GetValue() / 100
			local a = self.a_slider:GetValue() / 100
			local h, s = self.hsv[1], self.hsv[2]

			self.hsv[3] = v
			local r, g, b = hsvToRgb(h, s, v)
			self:SetColor(r, g, b, a, "sliders")
		end
		v_slider.OnValueChanged = updateFromSliders
		a_slider.OnValueChanged = updateFromSliders

		-- 5. Preview Panel
		local preview = loveframes.objects["panel"]:new()
		preview.parent = self
		preview.Draw = function(object)
			if object.drawfunc then
				object.drawfunc(object)
			end
			local x, y = object:GetPos()
			local w, h = object:GetSize()
			local r, g, b, a = unpack(self.color)

			-- Transparency checkerboard
			if a < 1 then
				love.graphics.setColor(1, 1, 1, 1)
				love.graphics.rectangle("fill", x + 4, y + 4, w - 8, h - 8)
				love.graphics.setColor(0.8, 0.8, 0.8, 1)
				local sq = 5
				local sx, sy = x + 4, y + 4
				local sw, sh = w - 8, h - 8
				love.graphics.setScissor(sx, sy, sw, sh)
				for gy = sy, sy + sh, sq * 2 do
					for gx = sx, sx + sw, sq * 2 do
						love.graphics.rectangle("fill", gx, gy, sq, sq)
						love.graphics.rectangle("fill", gx + sq, gy + sq, sq, sq)
					end
				end
				love.graphics.setScissor()
			end

			love.graphics.setColor(r, g, b, a)
			love.graphics.rectangle("fill", x + 4, y + 4, w - 8, h - 8)
		end
		self.preview = preview
		table.insert(self.internals, preview)

		-- 6. Hex Row
		self.hex_lbl = loveframes.objects["label"]:new()
		self.hex_lbl.parent = self
		self.hex_lbl:SetText("Hex: #")
		table.insert(self.internals, self.hex_lbl)

		local hex_input = loveframes.objects["textbox"]:new()
		hex_input.parent = self
		hex_input:SetUsable({ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "A", "B",
			"C", "D", "E", "F" })
		hex_input:SetCharacterLimit(8)
		hex_input:SetText("FFFFFFFF")
		hex_input.OnTextChanged = function(object)
			if self.updating_gui then return end
			local text = object:GetText()
			if #text == 6 or #text == 8 then
				local r, g, b, a = hexToRgba(text)
				if r then
					self:SetColor(r, g, b, a, "hex")
				end
			end
		end
		self.hex_input = hex_input
		table.insert(self.internals, hex_input)

		-- 7. RGB Value display Label
		self.rgb_lbl = loveframes.objects["textbox"]:new()
		self.rgb_lbl.parent = self
		self.rgb_lbl:SetMultiline(true)
		self.rgb_lbl:SetText("255, 255, 255, 255\n1.00, 1.00, 1.00, 1.00")
		table.insert(self.internals, self.rgb_lbl)

		self:SetDrawFunc()
	end

	--[[---------------------------------------------------------
	- func: update(deltatime)
	- desc: updates the object
--]] ---------------------------------------------------------
	function newobject:update(dt)
		if not self:OnState() then return end
		if not self:isUpdating() then return end
		self:CheckHover()

		local parent = self.parent
		local base = loveframes.base
		if parent ~= base then
			self.x = self.parent.x + self.staticx
			self.y = self.parent.y + self.staticy
		end

		for k, v in ipairs(self.internals) do
			v:update(dt)
		end

		local update = self.Update
		if update then
			update(self, dt)
		end
	end

	--[[---------------------------------------------------------
	- func: mousepressed(x, y, button)
	- desc: handles mouse click to focus
--]] ---------------------------------------------------------
	function newobject:mousepressed(x, y, button)
		if not self:OnState() then return end
		if not self:isUpdating() then return end

		local hover = self.hover
		if hover and button == 1 then
			local baseparent = self:GetBaseParent()
			if baseparent and baseparent.type == "frame" then
				baseparent:MakeTop()
			end
		end

		for k, v in ipairs(self.internals) do
			v:mousepressed(x, y, button)
		end
	end

	--[[---------------------------------------------------------
	- func: SetColor(r, g, b, a, source)
	- desc: sets the colorpicker's active color
--]] ---------------------------------------------------------
	function newobject:SetColor(r, g, b, a, source)
		if type(r) == "table" then
			r, g, b, a = r[1], r[2], r[3], r[4] or 1
		end
		r = r or 1
		g = g or 1
		b = b or 1
		a = a or 1

		local old_r, old_g, old_b, old_a = unpack(self.color)
		local changed = (r ~= old_r) or (g ~= old_g) or (b ~= old_b) or (a ~= old_a)
		self.color = { r, g, b, a }

		-- Calculate HSV representation
		local h, s, v = rgbToHsv(r, g, b)
		self.hsv = { h, s, v }

		self.updating_gui = true

		-- Sync sliders
		if source ~= "sliders" then
			self.v_slider:SetValue(v * 100)
			self.a_slider:SetValue(a * 100)
		end

		-- Sync Hex input
		if source ~= "hex" then
			local hex_str = rgbaToHex(r, g, b, a)
			self.hex_input:SetText(hex_str)
		end

		self.updating_gui = false

		-- Update text label details
		self.rgb_lbl:SetText(string.format("%d, %d, %d, %d\n%.2f, %.2f, %.2f, %.2f",
			r * 255 + 0.5,
			g * 255 + 0.5,
			b * 255 + 0.5,
			a * 255 + 0.5,
			r, g, b, a
		))

		if changed and self.OnColorChanged then
			self.OnColorChanged(self, r, g, b, a)
		end

		return self
	end

	--[[---------------------------------------------------------
	- func: GetColor()
	- desc: returns the active color (r, g, b, a)
--]] ---------------------------------------------------------
	function newobject:GetColor()
		return unpack(self.color)
	end

	--[[---------------------------------------------------------
	- func: RedoLayout()
	- desc: positions sub-widgets dynamically based on size
--]] ---------------------------------------------------------
	function newobject:RedoLayout()
		local content_height = self.height - 20
		local wheel_size = math.floor(content_height * 0.9)
		if wheel_size < 30 then wheel_size = 30 end

		local R = math.floor(wheel_size / 2)
		wheel_size = R * 2

		-- Wheel layout
		self.wheel_lbl:SetPos(5, 2)
		self.wheel:SetPos(5, 18)
		self.wheel:SetSize(wheel_size, wheel_size)

		-- Regenerate wheel image if size changed
		if not self.wheel_img or self.wheel_img:getWidth() ~= wheel_size then
			if self.wheel_img then
				self.wheel_img:release()
			end
			self.wheel_img = generateColorWheel(R)
		end

		-- Brightness Slider (Value) layout
		local v_x = 5 + wheel_size + 10
		self.v_lbl:SetPos(v_x, 2)
		self.v_slider:SetPos(v_x, 18)
		self.v_slider:SetSize(12, wheel_size)
		self.v_slider:RedoLayout()

		-- Alpha Slider layout
		local a_x = v_x + 22
		self.a_lbl:SetPos(a_x, 2)
		self.a_slider:SetPos(a_x, 18)
		self.a_slider:SetSize(12, wheel_size)
		self.a_slider:RedoLayout()

		-- Right Area Layout
		local right_x = a_x + 22
		local right_width = self.width - right_x - 5

		-- Preview layout
		self.preview:SetPos(right_x, 18)
		self.preview:SetSize(right_width, math.floor(wheel_size * 0.2))

		-- Hex row layout
		local hex_y = 18 + math.floor(wheel_size * 0.2) + 5
		self.hex_lbl:SetPos(right_x, hex_y + 3)

		local hex_lbl_w = 40
		self.hex_input:SetPos(right_x + hex_lbl_w, hex_y)
		self.hex_input:SetSize(right_width - hex_lbl_w, 20)

		-- RGB values info layout
		local rgb_y = hex_y + 25
		self.rgb_lbl:SetPos(right_x, wheel_size * 0.5 + 18)
		self.rgb_lbl:SetSize(right_width, math.floor(wheel_size * 0.5))

		return self
	end

	---------- module end ----------
end
