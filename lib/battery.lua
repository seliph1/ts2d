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

return battery