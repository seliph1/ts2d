--[[-----------------------------------------------------------------------------
	-- Env_Sound Entity Class (Type 23)
	-- Encapsulates sound emitter entity.
-------------------------------------------------------------------------------]]

local Entity = require "core.entities.base"

local EnvSound = setmetatable({}, { __index = Entity })
EnvSound.__index = EnvSound

function EnvSound.new(data)
	local self = Entity.new(data)
	setmetatable(self, EnvSound)
	return self
end

function EnvSound:onToggle(activator, source_id, server)
	local sound_file = self:getStr(1)
	if sound_file and sound_file ~= "" and server and server.send then
		server.send("all", string.format("sound %s %d %d", sound_file, self.x * 32 + 16, self.y * 32 + 16))
	end
end

return EnvSound
