--[[-----------------------------------------------------------------------------
	-- Entity Base Class
	-- Base object class for all CS2D map entities.
-------------------------------------------------------------------------------]]

local Database = require "core.entities.database"

---@class Entity
---@field name string
---@field type number
---@field x number
---@field y number
---@field trigger string
---@field number_settings table<number, number>
---@field string_settings table<number, string>
---@field object_type string
---@field disabled boolean
---@field state any
---@field index number
---@field depth number
---@field schema table|nil
local Entity = {}
Entity.__index = Entity

--- Creates a new Entity instance from raw entity table data
---@param data table
---@return Entity
function Entity.new(data)
	local self = setmetatable({}, Entity)
	data = data or {}

	self.name = data.name or ""
	self.type = data.type or 0
	self.x = data.x or 0
	self.y = data.y or 0
	self.trigger = data.trigger or ""
	self.number_settings = data.number_settings or { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
	self.string_settings = data.string_settings or { "", "", "", "", "", "", "", "", "", "" }
	self.object_type = "entity"
	self.index = data.index or 0
	self.depth = data.depth or 0

	self.schema = Database.get(self.type)
	return self
end

--- Get 1-based integer parameter
---@param idx number 1..10
---@return number
function Entity:getInt(idx)
	return self.number_settings[idx] or 0
end

--- Get 1-based string parameter
---@param idx number 1..10
---@return string
function Entity:getStr(idx)
	return self.string_settings[idx] or ""
end

--- Get parameter by schema name (e.g. "size_x", "filepath")
---@param param_name string
---@return any
function Entity:getParam(param_name)
	if self.schema.int_schema then
		for idx, name in pairs(self.schema.int_schema) do
			if name == param_name then
				return self:getInt(idx)
			end
		end
	end
	if self.schema.str_schema then
		for idx, name in pairs(self.schema.str_schema) do
			if name == param_name then
				return self:getStr(idx)
			end
		end
	end
	return nil
end

--- Set parameter by schema name
---@param param_name string
---@param value any
function Entity:setParam(param_name, value)
	if self.schema.int_schema then
		for idx, name in pairs(self.schema.int_schema) do
			if name == param_name then
				self.number_settings[idx] = tonumber(value) or 0
				return true
			end
		end
	end
	if self.schema.str_schema then
		for idx, name in pairs(self.schema.str_schema) do
			if name == param_name then
				self.string_settings[idx] = tostring(value or "")
				return true
			end
		end
	end
	return false
end

--- Called when entity is loaded into the map
---@param map table
function Entity:onInit(map)
	-- Virtual method
end

--- Called on tick update
---@param dt number
---@param map table
function Entity:onUpdate(dt, map)
	-- Virtual method
end

--- Called when triggered / activated
---@param activator table|nil
---@param source_id number|nil
---@param server table|nil
function Entity:onToggle(activator, source_id, server)
	-- Virtual method
end

--- Called when a player walks over entity position
---@param player table
---@param map table
function Entity:onWalk(player, map)
	-- Virtual method
end

--- Called when touched by another entity/object
---@param other table
---@param map table
function Entity:onTouch(other, map)
	-- Virtual method
end

--- Returns physics body / bounding box data for Bump.lua integration
---@param map table|nil
---@return table body { x, y, w, h, isSolid, isTrigger }
function Entity:getPhysicsBody(map)
	return {
		x = self.x * 32,
		y = self.y * 32,
		w = 32,
		h = 32,
		isSolid = false,
		isTrigger = false,
	}
end

--- Synchronize entity disabled/state property to networked share.entities table
---@param server table|nil
function Entity:syncState(server)
	local share = server and server.share
	if share and share.entities and self.index and self.index > 0 then
		share.entities[self.index] = {
			state = self.state,
		}
	end
end

--- Get state value from networked share or local fallback
---@param context table|nil (client or server object containing share)
---@return any
function Entity:getState(context)
	local share = context and context.share
	if share and share.entities and self.index and share.entities[self.index] then
		local net = share.entities[self.index]
		if net.state ~= nil then return net.state end
	end
	return self.state
end

function Entity:setState(state)
	self.state = state
end

return Entity
