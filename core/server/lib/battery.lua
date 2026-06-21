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

function battery.rstring(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, length do
        local rand = math.random(#charset)
        result[i] = charset:sub(rand, rand)
    end
    return table.concat(result)
end
battery.random_string = battery.rstring

function battery.rcolor(prefix)
	prefix = prefix or "©" 
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)
    return string.format("%s%03d%03d%03d", prefix, r, g, b)
end
battery.random_color = battery.rcolor


function battery.normalize(x, y, width, height)
	return x - width/2, y - height/2
end

return battery