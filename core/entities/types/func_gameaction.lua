--[[-----------------------------------------------------------------------------
	-- Func_GameAction Entity Class (Type 73)
	-- Encapsulates console action command execution on trigger.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local FuncGameAction = setmetatable({}, { __index = Entity })
FuncGameAction.__index = FuncGameAction

function FuncGameAction.new(data)
	local self = Entity.new(data)
	setmetatable(self, FuncGameAction)
	return self
end

function FuncGameAction:onToggle(activator, source_id, server)
	local action_cmd = self:getStr(1)
	if action_cmd and action_cmd ~= "" and server and server.parse then
		server.parse(source_id or 0, action_cmd)
	end
end

return FuncGameAction
