--[[
    hrc/textures.lua
    Canvas and texture management for Volumetric HRC.
--]]

local textures = {}

-- Helper to create a single Canvas with proper filter and wrap modes
local function create_canvas(w, h, format)
    local canvas = love.graphics.newCanvas(w, h, { format = format })
    canvas:setFilter("nearest", "nearest")
    canvas:setWrap("clamp", "clamp")
    return canvas
end

-- Builds all canvases required for HRC pipeline
function textures.buildAll(w, h, cascades)
    local state = {
        width = w,
        height = h,
        cascades = cascades,
        
        -- Scene Buffers (8-bit UNORM)
        emissivity = create_canvas(w, h, "rgba8"),
        absorption = create_canvas(w, h, "rgba8"),
        linearEmsv = create_canvas(w, h, "rgba8"),
        linearAbsr = create_canvas(w, h, "rgba8"),
        
        -- Output and Radiance Buffers (16-bit Float HDR)
        fluences = create_canvas(w, h, "rgba16f"),
        
        -- Cascades temporary radiance array (cascades - 1)
        radiance = {},
        
        -- Frustums final radiance array (4 directions)
        frustums = {}
    }
    
    -- Build radiance cascading surfaces (cascades - 1 elements, i.e., index 1 to cascades - 1)
    for i = 1, cascades - 1 do
        state.radiance[i] = create_canvas(w, h, "rgba16f")
    end
    
    -- Build 4 frustum final direction surfaces
    for i = 1, 4 do
        state.frustums[i] = create_canvas(w, h, "rgba16f")
    end
    
    return state
end

-- Safely releases/destroys all canvases by setting them to nil
-- In Lua, GC will free the graphics memory when no references exist.
function textures.destroyAll(state)
    if not state then return end
    
    state.emissivity = nil
    state.absorption = nil
    state.linearEmsv = nil
    state.linearAbsr = nil
    state.fluences = nil
    
    for i = 1, #state.radiance do
        state.radiance[i] = nil
    end
    state.radiance = nil
    
    for i = 1, #state.frustums do
        state.frustums[i] = nil
    end
    state.frustums = nil
    
    state.width = 0
    state.height = 0
    state.cascades = 0
end

-- Clears emissivity and absorption canvases to black (with alpha 0)
function textures.clearScene(state)
    love.graphics.push("all")
    
    -- Clear Emissivity
    love.graphics.setCanvas(state.emissivity)
    love.graphics.clear(0, 0, 0, 0)
    
    -- Clear Absorption
    love.graphics.setCanvas(state.absorption)
    love.graphics.clear(0, 0, 0, 0)
    
    love.graphics.pop()
end

return textures
