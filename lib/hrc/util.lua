--[[
    hrc/util.lua
    Utility mathematics functions for Volumetric HRC, ported from GameMaker Scr_HelperFunctions.gml.
--]]

local util = {}

-- Base-2 logarithm helper
function util.log2(x)
    return math.log(x) / 0.6931471805599453 -- math.log(2)
end

-- Checks if a number is a positive integer and power of 2
function util.isPowerOf2(x)
    if type(x) ~= "number" or x <= 0 or x % 1 ~= 0 then
        return false
    end
    -- Bitwise AND in Lua 5.3+ / LuaJIT
    return bit.band(x, x - 1) == 0
end

-- Clamp a value between min and max
function util.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

-- Aligns a number to the next power of N
-- Original GML: function power_ofN(number, n) { return power(n, ceil(logn(n, number))); }
function util.power_ofN(number, n)
    local logN = math.log(number) / math.log(n)
    return n ^ math.ceil(logN)
end

-- Aligns a number to the next multiple of N
-- Original GML: function multiple_ofN(number, n) { return (n == 0) ? number : ceil(number / n) * n; }
function util.multiple_ofN(number, n)
    if n == 0 then
        return number
    end
    return math.ceil(number / n) * n
end

-- Computes the sum of a geometric progression
-- Original GML: function geometric_ofN(number, n, p) { return (number * (1.0 - power(p, n))) / (1.0 - p); }
function util.geometric_ofN(number, n, p)
    if p == 1 then
        return number * n
    end
    return (number * (1.0 - (p ^ n))) / (1.0 - p)
end

-- Computes ceil(log2(max(w, h)))
-- Original GML: function log2_ofWH(w,h) { return ceil(log2(max(w,h))); }
function util.log2_ofWH(w, h)
    return math.ceil(util.log2(math.max(w, h)))
end

return util
