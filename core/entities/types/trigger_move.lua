--[[-----------------------------------------------------------------------------
	-- Trigger_Move Entity Class (Type 91)
	-- Triggers when players walk over it.
	-- int[1]: triggered by (0=everyone, 1=terrorists, 2=counter-terrorists, 3=team 3/VIP, etc.)
	-- int[2]: width in tiles (default 1)
	-- int[3]: height in tiles (default 1)
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local TriggerMove = setmetatable({}, { __index = Entity })
TriggerMove.__index = TriggerMove

function TriggerMove.new(data)
	local self = Entity.new(data)
	setmetatable(self, TriggerMove)
	self.disabled = false
	self.state = 0
	self.initial_state = 0
	self.initial_disabled = false
	return self
end

function TriggerMove:getPhysicsBody(map)
	local w = math.max(1, self:getInt(2))
	local h = math.max(1, self:getInt(3))
	return {
		x = self.x * 32,
		y = self.y * 32,
		w = w * 32,
		h = h * 32,
		isSolid = false,
		isTrigger = true,
	}
end

--- Called when a player walks into the trigger area
---@param player table
---@param peer_id number|nil
---@param server table|nil
function TriggerMove:onWalk(player, peer_id, server)
	if self.disabled or self.state == 1 then return end

	local team_filter = self:getInt(1)
	if team_filter and team_filter > 0 then
		local player_team = player and player.t or 0
		if player_team ~= team_filter then
			return
		end
	end

	if self.trigger and self.trigger ~= "" and server and server.trigger then
		server.trigger(self.trigger, peer_id or 0, self.x, self.y)
	end
end

--- Called when targeted by another trigger to toggle enabled/disabled state
function TriggerMove:onToggle(activator, source_id, server)
	self.state = (self.state == 1) and 0 or 1
	self.disabled = (self.state == 1)
	if server then
		self:syncState(server)
	end
end

return TriggerMove

