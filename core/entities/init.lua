--[[-----------------------------------------------------------------------------
	-- Entity Factory & Registry
	-- Instantiates entity objects based on type_id using specialized subclasses.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"
local Database = require "core.entities.database"

local EnvSprite = require "core.entities.types.env_sprite"
local EnvSound = require "core.entities.types.env_sound"
local FuncTeleport = require "core.entities.types.func_teleport"
local FuncDynWall = require "core.entities.types.func_dynwall"
local FuncMessage = require "core.entities.types.func_message"
local FuncGameAction = require "core.entities.types.func_gameaction"
local TriggerUse = require "core.entities.types.trigger_use"

local Entities = {}
Entities.Database = Database
Entities.Base = Entity

-- Map entity type IDs to subclass constructors
Entities.registry = {
	[22] = EnvSprite,
	[23] = EnvSound,
	[70] = FuncTeleport,
	[71] = FuncDynWall,
	[72] = FuncMessage,
	[73] = FuncGameAction,
	[93] = TriggerUse,
}

--- Creates an Entity instance from a raw entity table data
---@param data table
---@return Entity
function Entities.create(data)
	if type(data) == "table" and data.object_type == "entity" and getmetatable(data) then
		return data -- Already an Entity object instance
	end

	local type_id = data and data.type or 0
	local class = Entities.registry[type_id] or Entity
	return class.new(data)
end

function Entities.dump()
	return Entities.Database.dump()
end

return Entities
