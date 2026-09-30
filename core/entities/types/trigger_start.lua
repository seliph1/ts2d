--[[-----------------------------------------------------------------------------
	-- Trigger_Start Entity Class (Type 90)
	-- Triggers entities directly at round start.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local TriggerStart = setmetatable({}, { __index = Entity })
TriggerStart.__index = TriggerStart

function TriggerStart.new(data)
	local self = Entity.new(data)
	setmetatable(self, TriggerStart)
	self.disabled = false
	self.state = 0
	return self
end

--- Called when a round starts on the server
---@param server table
function TriggerStart:onRoundStart(server)
	if self.disabled or self.state == 1 then return end
	if self.trigger and self.trigger ~= "" and server and server.trigger then
		server.trigger(self.trigger, 0, self.x, self.y)
	end
end

--- Called when activated by another trigger signal
function TriggerStart:onToggle(activator, source_id, server, active_set, depth)
	if self.disabled or self.state == 1 then return end
	if self.trigger and self.trigger ~= "" and server and server.trigger then
		server.trigger(self.trigger, source_id or 0, self.x, self.y, active_set, depth)
	end
end

return TriggerStart

