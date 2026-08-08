--[[-----------------------------------------------------------------------------
	-- Func_DynWall Entity Class (Type 71)
	-- Encapsulates dynamic wall / door behavior, state toggling, and rendering.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local FuncDynWall = setmetatable({}, { __index = Entity })
FuncDynWall.__index = FuncDynWall

function FuncDynWall.new(data)
	local self = Entity.new(data)
	setmetatable(self, FuncDynWall)
	self.state = data.state or 0 -- 1 = closed (visible/solid), 0 = open (hidden/passable)
	return self
end

function FuncDynWall:onToggle(activator, source_id, server)
	self.state = (self.state == 1) and 0 or 1
	self:syncState(server)
end

function FuncDynWall:getPhysicsBody(map, client)
	local state = self:getState(client)
	local w = math.max(1, self:getInt(4))
	local h = math.max(1, self:getInt(5))
	return {
		x = self.x * 32,
		y = self.y * 32,
		w = w * 32,
		h = h * 32,
		isSolid = (state == 1),
		isTrigger = false,
	}
end

function FuncDynWall:draw(mapengine, client)
	--if self:getState(client) == 1 then return end
	if self.state == 1 then return end

	if client.debug_level == 2 then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.rectangle("line", self.x * 32, self.y * 32, 32, 32)
	end

	local tile_index = self:getInt(1)
	local mapdata = mapengine._mapdata
	local tile_img = mapdata and mapdata.gfx and mapdata.gfx.tile and mapdata.gfx.tile[tile_index]

	if tile_img then
		local alpha_str = self:getStr(1)
		local inverse_alpha = (alpha_str and alpha_str ~= "") and tonumber(alpha_str) or 1.0
		local alpha = 1.0 + inverse_alpha

		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.setBlendMode("alpha")
		love.graphics.draw(tile_img, self.x * 32, self.y * 32)
	end
end

return FuncDynWall
