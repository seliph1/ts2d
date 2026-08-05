--[[-----------------------------------------------------------------------------
	-- Env_Sprite Entity Class (Type 22)
	-- Encapsulates map sprite visual entity rendering and physics body logic.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"
local rad = math.rad

local EnvSprite = setmetatable({}, { __index = Entity })
EnvSprite.__index = EnvSprite

function EnvSprite.new(data)
	local self = Entity.new(data)
	setmetatable(self, EnvSprite)
	return self
end

function EnvSprite:getPhysicsBody(map)
	local size_x = self:getInt(1)
	local size_y = self:getInt(2)
	local shift_x = self:getInt(3)
	local shift_y = self:getInt(4)
	return {
		x = self.x * 32 + shift_x,
		y = self.y * 32 + shift_y,
		w = size_x > 0 and size_x or 32,
		h = size_y > 0 and size_y or 32,
		isSolid = false,
		isTrigger = false,
	}
end

function EnvSprite:draw(mapengine, client)
	local path = self:getStr(1)
	if not path or path == "" then return end

	local mapdata = mapengine._mapdata
	if not mapdata or not mapdata.gfx or not mapdata.gfx.entity then return end

	local sprite = mapdata.gfx.entity[path]
	if not sprite then return end

	local width = sprite:getWidth()
	local height = sprite:getHeight()
	local size_x = self:getInt(1)
	local size_y = self:getInt(2)
	local shift_x = self:getInt(3)
	local shift_y = self:getInt(4)
	local rotation = -self:getInt(5)
	local red = self:getInt(6)
	local green = self:getInt(7)
	local blue = self:getInt(8)
	local fx = self:getInt(9)
	local blend = self:getInt(10)

	local alpha_str = self:getStr(2)
	local mask_str = self:getStr(3)
	local rot_str = self:getStr(4)

	local alpha = (tonumber(alpha_str) or 1) * 255
	local mask = (tonumber(mask_str) or 0)
	local rotationspeed = (tonumber(rot_str) or 0)
	local angle = rad(rotation + rotationspeed * love.timer.getTime() * 90)

	local scale_x = size_x / width
	local scale_y = size_y / height
	local sx = (self.x * 32) + shift_x + size_x / 2
	local sy = (self.y * 32) + shift_y + size_y / 2
	local entity_shader = mapengine._entity_shader

	if blend == 0 then
		love.graphics.setBlendMode("alpha")
	elseif blend == 3 then
		love.graphics.setBlendMode("screen", "premultiplied")
	elseif blend == 4 then
		love.graphics.setBlendMode("multiply", "premultiplied")
	elseif blend == 6 then
		love.graphics.setBlendMode("alpha")
	else
		love.graphics.setBlendMode("add")
	end

	if entity_shader then
		entity_shader:send("mask", mask)
		entity_shader:send("blend", blend)
	end

	love.graphics.setColor(love.math.colorFromBytes(red, green, blue, alpha))
	love.graphics.draw(sprite, sx, sy, angle, scale_x, scale_y, width / 2, height / 2)
	love.graphics.setBlendMode("alpha")

	if entity_shader then
		entity_shader:send("mask", 0)
		entity_shader:send("blend", 0)
	end
end

return EnvSprite
