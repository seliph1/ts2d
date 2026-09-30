--[[
    hrc/probes.lua
    Probe placement, alignment, and coordinate rotation mathematics.
    Ported from Shd_MergingHRC.fsh and Obj_LightSystem Draw_73.gml.
--]]

local probes = {}

-- Rotates a probe coordinate based on the frustum index (0 to 3)
-- Matches frustRot() in Shd_MergingHRC.fsh.
-- frustum_index: 0 (Right), 1 (Down), 2 (Left), 3 (Up)
-- extent_w, extent_h: resolution dimensions of the grid
function probes.rotate(x, y, frustum_index, extent_w, extent_h)
    local rx, ry = x, y
    
    -- Step 1: Swap coordinates on odd frustum indices
    if frustum_index % 2 == 1 then
        rx, ry = y, x
    end
    
    -- Step 2: Invert coordinates on frustum index 1 and 2
    local mod_3 = frustum_index % 3
    if mod_3 >= 0.5 then
        rx = extent_w - rx
        ry = extent_h - ry
    end
    
    return rx, ry
end

-- Calculates the probe's base coordinates and spacing alignment
-- plane: index of the plane along the X axis
-- intrv: spacing interval of the current cascade (2^cascade_index)
function probes.getProbeX(plane, intrv)
    return plane * intrv + 0.5
end

-- Calculates alignment factor (palign in shader)
-- Odd planes align (1.0), even planes interpolate with near/far (2.0)
function probes.getAlignment(plane)
    return 2.0 - (plane % 2)
end

return probes
