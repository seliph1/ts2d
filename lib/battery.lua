local battery = {}

---Linear interpolation from A to B
---@param a number Current position
---@param b number Future position
---@param t number Speed factor
---@return number i Interpolated position
function battery.lerp(a, b, t)
	return a + (b - a) * t
end
---Returns a random index from a lua table
---@param tbl table
---@return number index
function battery.rift(tbl)
	local tk = {}
	for k, v in pairs(tbl) do
		tk[#tk+1] = k
	end
	return tk[ math.random(1, #tk) ]
end

function battery.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[battery.deepcopy(orig_key)] = battery.deepcopy(orig_value)
        end
        setmetatable(copy, battery.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return battery