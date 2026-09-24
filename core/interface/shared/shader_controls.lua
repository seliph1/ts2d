local LF = require "lib.loveframes"

return function(ui)
--shader controls---------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
function ui.shader_controls(shader, fields, name)
	name = name or "Shader"
	local fields_offset = 300
	local shader_frame = LF.Create("frame")
		:SetName(name .. " controls")
		:SetSize(500, #fields * 25 + 30)
		:SetState("*")
		:Center()
	--:SetVisible(false)
	fields.storage = {}

	for i = 1, #fields do
		local field = LF.Create("slider", shader_frame)
		local component = fields[i].component
		local uniform = fields[i].name

		field:SetPos(5, (i - 1) * 25 + 30)
		field:SetMinMax(fields[i].hint[1], fields[i].hint[2])
		field:SetWidth(fields_offset)

		local value = LF.Create("label", shader_frame)
		value:SetPos(fields_offset + 10, (i - 1) * 25 + 30)

		function field:Update()
			local v = self:GetValue()
			if fields[i].integer == true then
				v = math.floor(v)
			end
			local text = tostring(v) or ""
			value:SetText(text)
		end

		function field:OnValueChanged(v)
			if fields[i].integer == true then
				v = tonumber(v)
				v = math.floor(v)
			end

			-- Custom setter: route the value somewhere other than a raw uniform
			if fields[i].apply then
				fields[i].apply(tonumber(v))
				return
			end

			if component then
				fields.storage[uniform] = fields.storage[uniform] or { 0.0, 0.0, 0.0, 0.0 }
				local storage = fields.storage[uniform]
				local n = tonumber(v)

				storage[component] = n

				if shader:hasUniform(uniform) then
					shader:send(uniform, storage)
				end
			else
				local n = tonumber(v)
				if shader:hasUniform(uniform) then
					shader:send(uniform, n)
				end
			end
		end

		field:SetValue(fields[i].init_value)
		local label = LF.Create("label", shader_frame)
		if component then
			label
				:SetPos(fields_offset + 100, (i - 1) * 25 + 32)
				:SetText(string.format("%s[%s]", uniform, component))
		else
			label:SetPos(fields_offset + 100, (i - 1) * 25 + 32):SetText(uniform)
		end
	end
end


end
