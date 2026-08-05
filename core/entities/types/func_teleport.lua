--[[-----------------------------------------------------------------------------
	-- Func_Teleport Entity Class (Type 70)
	-- Encapsulates teleporter gate logic, toggle state, and player teleportation.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local FuncTeleport = setmetatable({}, { __index = Entity })
FuncTeleport.__index = FuncTeleport

function FuncTeleport.new(data)
	local self = Entity.new(data)
	setmetatable(self, FuncTeleport)
	return self
end

function FuncTeleport:onToggle(activator, source_id, server)
	if self.state == 1 then
		self.state = 0
	else
		self.state = 1
	end
	self:syncState(server)
end

function FuncTeleport:getPhysicsBody(map)
	return {
		x = self.x * 32,
		y = self.y * 32,
		w = 32,
		h = 32,
		isSolid = false,
		isTrigger = true,
	}
end

function FuncTeleport:onWalk(player, peer_id, server)
	if self:isDisabled(server) then return end

	local dest_tx = self:getInt(1)
	local dest_ty = self:getInt(2)
	local dest_x = dest_tx * 32 + 16
	local dest_y = dest_ty * 32 + 16

	player.x = dest_x
	player.y = dest_y
end

return FuncTeleport
