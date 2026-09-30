--[[
    hrc/renderer.lua
    Execution pipeline for Volumetric HRC.
--]]

local parent_path = (...):match("(.-)[^%.]+$") or ""
local cascades = require(parent_path .. "cascades")

local renderer = {}

-- Main process function that runs the HRC shader pipeline
-- state: the HRC state containing canvases
-- shaders: table of compiled shaders
function renderer.process(state, shaders)
    -- Push all graphics state to avoid polluting user's state
    love.graphics.push("all")
    
    -- Disables blending, matching GameMaker gpu_set_blendenable(false)
    love.graphics.setBlendMode("none")
    
    -- Step 1: Convert emissivity to linear space
    love.graphics.setCanvas(state.linearEmsv)
    love.graphics.setShader(shaders.srgb_to_linear)
    love.graphics.draw(state.emissivity, 0, 0)
    
    -- Step 2: Convert absorption to linear space
    love.graphics.setCanvas(state.linearAbsr)
    love.graphics.setShader(shaders.srgb_to_linear)
    love.graphics.draw(state.absorption, 0, 0)
    
    -- Step 3: Compute all four frustums
    local merging_shd = shaders.merging_hrc
    love.graphics.setShader(merging_shd)
    
    -- Send static uniforms for merging shader
    merging_shd:send("merging_extent", {state.width, state.height})
    merging_shd:send("merging_emissivity", state.linearEmsv)
    merging_shd:send("merging_absorption", state.linearAbsr)
    
    -- Loop through 4 frustums (j = 0 to 3)
    for j = 0, 3 do
        -- Loop through cascades reversely (i = cascades - 1 down to 0)
        for i = state.cascades - 1, 0, -1 do
            -- Resolve current (target) and next (source) canvases
            -- Pass 1-based index (j + 1) for frustum lookup in Lua arrays
            local surf_curr, surf_next = cascades.resolveCanvases(i, j + 1, state)
            
            -- Send cascade-specific and frustum-specific indices
            merging_shd:send("merging_indices", {i, j})
            merging_shd:send("merging_previous", surf_next)
            
            -- Set canvas target and run shader by drawing a fullscreen quad
            love.graphics.setCanvas(surf_curr)
            love.graphics.rectangle("fill", 0, 0, state.width, state.height)
        end
    end
    
    -- Step 4: Sum all 4 rendered frustum directions
    local fluence_shd = shaders.fluence_hrc
    love.graphics.setShader(fluence_shd)
    
    fluence_shd:send("fluence_extent", {state.width, state.height})
    fluence_shd:send("fluence_frustum0", state.frustums[1])
    fluence_shd:send("fluence_frustum1", state.frustums[2])
    fluence_shd:send("fluence_frustum2", state.frustums[3])
    fluence_shd:send("fluence_frustum3", state.frustums[4])
    
    -- Set output canvas and trigger summation
    love.graphics.setCanvas(state.fluences)
    love.graphics.rectangle("fill", 0, 0, state.width, state.height)
    
    -- Restore original graphics state
    love.graphics.pop()
end

return renderer
