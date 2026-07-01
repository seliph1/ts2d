--[[
    hrc/cascades.lua
    Cascade hierarchy and loop mathematics.
--]]

local cascades = {}

-- Calculates the number of cascade levels for a given resolution
function cascades.calculateCount(resolution)
    return math.ceil(math.log(resolution) / math.log(2))
end

-- Resolves the target (current) and source (next) canvases for a cascade pass
-- i: 0-based cascade index (from count - 1 down to 0)
-- frustum_index: 1-based frustum index (from 1 to 4)
-- state: the state table containing all canvases
function cascades.resolveCanvases(i, frustum_index, state)
    local cascades_count = state.cascades
    local surf_curr, surf_next
    
    if i == 0 then
        surf_curr = state.frustums[frustum_index]
        surf_next = state.radiance[1]
    elseif i == cascades_count - 1 then
        surf_curr = state.radiance[cascades_count - 1]
        surf_next = state.frustums[frustum_index]
    else
        surf_curr = state.radiance[i]
        surf_next = state.radiance[i + 1]
    end
    
    return surf_curr, surf_next
end

return cascades
