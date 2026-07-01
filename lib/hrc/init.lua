--[[
    hrc/init.lua
    Volumetric Hierarchical Radiance Cascades (HRC) Library for LÖVE 12.0.
    Organizes and exposes the HRC rendering API.
--]]

local raw_path = ... or ""
local module_path
if raw_path == "hrc" or raw_path == "hrc.init" then
    module_path = "hrc."
else
    if raw_path:sub(-5) == ".init" then
        module_path = raw_path:sub(1, -5) .. "."
    elseif raw_path ~= "" then
        module_path = raw_path .. "."
    else
        module_path = ""
    end
end
local file_path = module_path:gsub("%.", "/")

local util = require(module_path .. "util")
local textures = require(module_path .. "textures")
local probes = require(module_path .. "probes")
local cascades = require(module_path .. "cascades")
local renderer = require(module_path .. "renderer")

local HRC = {}
HRC.__index = HRC

-- Factory function to instantiate a new HRC renderer
-- resolution: size of the HRC grid along X and Y axes. Must be a power of 2 (e.g. 512, 1024, 2048).
function HRC.new(resolution)
    -- 1. Validation checks
    assert(util.isPowerOf2(resolution), "HRC resolution must be a positive integer and power of 2! Received: " .. tostring(resolution))
    local self = setmetatable({}, HRC)
    -- 2. Cascade count calculation
    local cascades_count = cascades.calculateCount(resolution)
    -- 3. Canvas memory allocation
    self.state = textures.buildAll(resolution, resolution, cascades_count)
    -- 4. GLSL shader compilation
    -- Retrieve shader code relative to the library installation path
    local srgb_code = love.filesystem.read(file_path .. "shaders/srgb_to_linear.glsl")
    local merging_code = love.filesystem.read(file_path .. "shaders/merging_hrc.glsl")
    local fluence_code = love.filesystem.read(file_path .. "shaders/fluence_hrc.glsl")
    assert(srgb_code, "Could not find srgb_to_linear.glsl shader file!")
    assert(merging_code, "Could not find merging_hrc.glsl shader file!")
    assert(fluence_code, "Could not find fluence_hrc.glsl shader file!")
    self.shaders = {
        srgb_to_linear = love.graphics.newShader(srgb_code),
        merging_hrc = love.graphics.newShader(merging_code),
        fluence_hrc = love.graphics.newShader(fluence_code)
    }
    self.state.resolution = resolution
    self.state.channel = 3
    return self
end

-- Renders emissive (light source) geometry into the emissivity buffer.
-- The buffer is cleared to transparent black prior to calling the callback.
function HRC:drawToEmissivity(draw_callback)
    -- Store previous scissor
    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.setScissor()
    love.graphics.push("all")
    love.graphics.setCanvas(self.state.emissivity)
    love.graphics.clear(0, 0, 0, 0)
    -- Reset transform/blend modes inside the draw target for clean rendering
    love.graphics.origin()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
    draw_callback()
    love.graphics.pop()
    love.graphics.setScissor(sx, sy, sw, sh)
end

-- Renders blocker and scattering media geometry into the absorption buffer.
-- The buffer is cleared to transparent black prior to calling the callback.
function HRC:drawToAbsorption(draw_callback)
    -- Store previous scissor
    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.setScissor()
    love.graphics.push("all")
    love.graphics.setCanvas(self.state.absorption)
    love.graphics.clear(0, 0, 0, 0)
    -- Reset transform/blend modes inside the draw target for clean rendering
    love.graphics.origin()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
    draw_callback()
    love.graphics.pop()
    love.graphics.setScissor(sx, sy, sw, sh)
end

-- Executes the HRC volumetric radiance cascading pipeline
function HRC:process(light_radius)
    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.setScissor()

    light_radius = light_radius or 10

    renderer.process(self.state, self.shaders, light_radius)
    love.graphics.setScissor(sx, sy, sw, sh)
end

-- Renders the final processed fluence texture to the screen
-- x, y: Position coordinates (default 0, 0)
-- w, h: Width and height of the destination rect (default matches window size)
function HRC:draw(x, y, w, h)
    -- Get window size and position
    x = x or 0
    y = y or 0
    w = w or love.graphics.getWidth()
    h = h or love.graphics.getHeight()
    local scaleX = w / self.state.width
    local scaleY = h / self.state.height
    love.graphics.push("all")
    love.graphics.setBlendMode("add", "premultiplied")
    love.graphics.setColor(1, 1, 1, 1)

    if self.state.channel == 1 then
        love.graphics.draw(self.state.emissivity, x, y, 0, scaleX, scaleY)
    elseif self.state.channel == 2 then
        love.graphics.draw(self.state.absorption, x, y, 0, scaleX, scaleY)
    elseif self.state.channel == 3 then
        love.graphics.draw(self.state.fluences, x, y, 0, scaleX, scaleY)
    end
    love.graphics.pop()
end


function HRC:getResolution()
    return self.state.resolution
end

function HRC:getScale(w, h)
    local sx = self.state.width / w
    local sy = self.state.height / h
    return sx, sy
end

-- Getters for internal canvases (useful for debugging and custom rendering setups)
function HRC:getEmissivity()
    return self.state.emissivity
end

-- Getters for linear space conversion surfaces
function HRC:getLinearEmissivity()
    return self.state.linearEmsv
end

function HRC:getAbsorption()
    return self.state.absorption
end

function HRC:getLinearAbsorption()
    return self.state.linearAbsr
end

function HRC:getFluences()
    return self.state.fluences
end

function HRC:getChannels()
    return self.state.emissivity, self.state.absorption, self.state.fluences
end

function HRC:getChannel()
    return self.state.channel
end

function HRC:setChannel(channel)
    self.state.channel = channel
    return self
end



-- Explicit destructor for clearing canvases and shader objects from graphics memory
function HRC:destroy()
    textures.destroyAll(self.state)
    self.state = nil
    self.shaders.srgb_to_linear = nil
    self.shaders.merging_hrc = nil
    self.shaders.fluence_hrc = nil
    self.shaders = nil
end

return HRC
