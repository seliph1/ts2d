--[[-----------------------------------------------------------------------------
	-- Trigger_Hit Entity Class (Type 92)
	-- Triggers entities when hit by bullets, melee attacks, or damage.
	-- Must be placed at a wall to work properly.
	-- int[1]: triggered by (0=everyone, 1=terrorists, 2=counter-terrorists, etc.)
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local TriggerHit = setmetatable({}, { __index = Entity })
TriggerHit.__index = TriggerHit

function TriggerHit.new(data)
	local self = Entity.new(data)
	setmetatable(self, TriggerHit)
	self.disabled = false
	self.state = 0
	self.initial_state = 0
	self.initial_disabled = false
	return self
end

function TriggerHit:getPhysicsBody(map)
	return {
		x = self.x * 32,
		y = self.y * 32,
		w = 32,
		h = 32,
		isSolid = false,
		isTrigger = true,
	}
end

--- Called when the wall or entity is hit by an attack
---@param attacker table|nil
---@param source_id number|nil
---@param server table|nil
function TriggerHit:onHit(attacker, source_id, server)
	if self.disabled or self.state == 1 then return end

	local team_filter = self:getInt(1)
	if team_filter and team_filter > 0 then
		local attacker_team = attacker and attacker.t or 0
		if attacker_team ~= team_filter then
			return
		end
	end

	if self.trigger and self.trigger ~= "" and server and server.trigger then
		server.trigger(self.trigger, source_id or 0, self.x, self.y)
	end
end

--- Called when targeted by another trigger to toggle enabled/disabled state
function TriggerHit:onToggle(activator, source_id, server)
	self.state = (self.state == 1) and 0 or 1
	self.disabled = (self.state == 1)
	if server then
		self:syncState(server)
	end
end

return TriggerHit

