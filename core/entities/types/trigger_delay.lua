--[[-----------------------------------------------------------------------------
	-- Trigger_Delay Entity Class (Type 94)
	-- Delays then fires its target trigger.
	-- int[1]: delay in milliseconds
	-- str[1]: delay in seconds (alternative format)
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local TriggerDelay = setmetatable({}, { __index = Entity })
TriggerDelay.__index = TriggerDelay

function TriggerDelay.new(data)
	local self = Entity.new(data)
	setmetatable(self, TriggerDelay)
	self.disabled = false
	self.state = 0
	self.initial_state = 0
	self.initial_disabled = false
	return self
end

--- Called when activated by a trigger signal
function TriggerDelay:onToggle(activator, source_id, server, active_set, depth)
	if self.disabled or self.state == 1 then return end
	if not self.trigger or self.trigger == "" or not server or not server.trigger then return end

	local delay_sec = tonumber(self:getStr(1)) or 0
	if delay_sec <= 0 then
		delay_sec = tonumber(self:getInt(1)) or 0
	end

	local delay_ms = math.floor(delay_sec * 1000)

	if delay_ms > 0 and server.timerex then
		local trigger_target = self.trigger
		local x, y = self.x, self.y
		server.timerex(delay_ms, 1, function()
			server.trigger(trigger_target, source_id or 0, x, y)
		end)
	else
		server.trigger(self.trigger, source_id or 0, self.x, self.y, active_set, depth)
	end
end

return TriggerDelay

