local shader = {}
local path = "core/shaders/"

--shader.entity = love.graphics.newShader("")

shader.entity = {}

--[[
local file

file = love.filesystem.read(path .. "reinhard.glsl")
shader.reinhard = love.graphics.newShader ( file )

file = love.filesystem.read(path .. "magenta.glsl")
shader.magenta = love.graphics.newShader ( file )

file = love.filesystem.read(path .. "shadow.glsl")
shader.shadow = love.graphics.newShader ( file )


file = love.filesystem.read(path .. "raycast.glsl")
shader.raycast = love.graphics.newShader( file )

file = love.filesystem.read(path .. "experiment.glsl")
shader.experiment = love.graphics.newShader( file )

--file = love.filesystem.read("shader/bleed.glsl")
--shader.bleed = love.graphics.newShader( file )

file = love.filesystem.read(path .. "windcover.glsl")
shader.wind = love.graphics.newShader( file )

file = love.filesystem.read(path .. "raycastshadow.glsl")
shader.raycasts = love.graphics.newShader( file )
]]
return shader