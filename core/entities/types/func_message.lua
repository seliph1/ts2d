--[[-----------------------------------------------------------------------------
	-- Func_Message Entity Class (Type 72)
	-- Encapsulates text message trigger activation.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local FuncMessage = setmetatable({}, { __index = Entity })
FuncMessage.__index = FuncMessage

function FuncMessage.new(data)
	local self = Entity.new(data)
	setmetatable(self, FuncMessage)
	return self
end

function FuncMessage:onToggle(activator, source_id, server)
	local msg = self:getStr(1)
	if msg and msg ~= "" and server and server.send then
		if source_id and source_id > 0 then
			server.send(source_id, "msg " .. msg)
		else
			server.send("all", "msg " .. msg)
		end
	end
end

return FuncMessage
