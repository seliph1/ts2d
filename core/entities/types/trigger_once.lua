--[[-----------------------------------------------------------------------------
	-- Trigger_Once Entity Class (Type 95)
	-- Forwards a trigger signal only once during a round.
	-- All following trigger signals in the round will not be forwarded.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local TriggerOnce = setmetatable({}, { __index = Entity })
TriggerOnce.__index = TriggerOnce

function TriggerOnce.new(data)
	local self = Entity.new(data)
	setmetatable(self, TriggerOnce)
	self.disabled = false
	self.state = 0
	self._triggered = false
	self.initial_state = 0
	self.initial_disabled = false
	return self
end

--- Called at round start to reset the one-time trigger
---@param server table
function TriggerOnce:onRoundStart(server)
	self._triggered = false
	self.state = self.initial_state or 0
	self.disabled = self.initial_disabled or false
	if server then
		self:syncState(server)
	end
end

--- Called when activated by a trigger signal
function TriggerOnce:onToggle(activator, source_id, server, active_set, depth)
	if self.disabled or self.state == 1 or self._triggered then return end

	self._triggered = true
	self.state = 1
	if server then
		self:syncState(server)
	end

	if self.trigger and self.trigger ~= "" and server and server.trigger then
		server.trigger(self.trigger, source_id or 0, self.x, self.y, active_set, depth)
	end
end

return TriggerOnce

