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
	self.state = data.state or 0 -- 0 = closed (visible/solid), 1 = open (hidden/passable)
	return self
end

function FuncDynWall:isSolid(context)
	local state = (context and self:getState(context)) or self.state
	return state == 0
end

function FuncDynWall:onToggle(activator, source_id, server)
	self.state = (self.state == 1) and 0 or 1
	self:syncState(server)
end

function FuncDynWall:getPhysicsBody(map, client)
	local w = math.max(1, self:getInt(4)) * 32
	local h = math.max(1, self:getInt(5)) * 32
	return {
		x = self.x * 32,
		y = self.y * 32,
		w = w,
		h = h,
		isSolid = self:isSolid(client),
		isTrigger = false,
	}
end

function FuncDynWall:draw(mapengine, client)
	if not self:isSolid(client) then return end

	local w = math.max(1, self:getInt(4))
	local h = math.max(1, self:getInt(5))

	if client.debug_level == 2 then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.rectangle("line", self.x * 32, self.y * 32, w * 32, h * 32)
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
		for tx = 0, w - 1 do
			for ty = 0, h - 1 do
				love.graphics.draw(tile_img, (self.x + tx) * 32, (self.y + ty) * 32)
			end
		end
	end
end

return FuncDynWall
