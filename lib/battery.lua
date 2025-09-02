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

function battery.get_vector(neg_x, pos_x, neg_y, pos_y, deadzone)
    -- força de cada direção (0 a 1)
    local LK = love.keyboard
    local nx = LK.isDown(neg_x) and 1 or 0
    local px = LK.isDown(pos_x) and 1 or 0
    local ny = LK.isDown(neg_y) and 1 or 0
    local py = LK.isDown(pos_y) and 1 or 0

    -- combina X e Y
    local x = px - nx
    local y = py - ny

    -- calcula magnitude
    local mag = math.sqrt(x*x + y*y)
    if mag == 0 then
        return 0, 0
    end

    -- aplica deadzone
    deadzone = deadzone or -1
    if deadzone < 0 then
        -- deadzone padrão (pode ajustar como quiser)
        deadzone = 0.25
    end
    if mag < deadzone then
        return 0, 0
    end

    -- normaliza e limita a 1
    local scale = 1 / mag
    return x * scale, y * scale
end

return battery