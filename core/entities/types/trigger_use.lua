--[[-----------------------------------------------------------------------------
	-- Trigger_Use Entity Class (Type 93)
	-- Encapsulates Key Use (E) trigger activation area.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local TriggerUse = setmetatable({}, { __index = Entity })
TriggerUse.__index = TriggerUse

function TriggerUse.new(data)
	local self = Entity.new(data)
	setmetatable(self, TriggerUse)
	return self
end

function TriggerUse:getPhysicsBody(map)
	local w = math.max(1, self:getInt(1))
	local h = math.max(1, self:getInt(2))
	return {
		x = self.x * 32,
		y = self.y * 32,
		w = w * 32,
		h = h * 32,
		isSolid = false,
		isTrigger = true,
	}
end

function TriggerUse:onToggle(activator, source_id, server)
	if self.trigger and self.trigger ~= "" and server and server.trigger then
		server.trigger(self.trigger, source_id or 0)
	end
end

return TriggerUse
