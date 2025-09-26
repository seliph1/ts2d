local List = {
	-- create instance
	new = function()

	end
}
List.__index = List

function List.new()
	local ins = {
		_count = 0,
		_first = nil,
		_last = nil,
		_value = {},
		_prev = {},
		_next = {}
	}
	return setmetatable(ins, List)
end

-- dummy value
local dummy = {}
local mmin = math.min
local mmax = math.max
local setmetatable = setmetatable

-- list count
function List:count()
    return self._count
end

-- first element in list
function List:first()
    return self._first
end

-- last element in list
function List:last()
    return self._last
end

-- contains
function List:contains(value)
    if value == nil then
        return false
    end
    return self._value[value] ~= nil
end

-- push to first
function List:pushf(value)
    if value == nil or self:contains(value) then
        return false
    end
    self._next[value] = self._first
    if self._first == nil then
        self._first = value
        self._last = value
    else
        self._prev[self._first] = value
        self._first = value
    end
    self._value[value] = dummy
    self._count = self._count + 1
    return true
end

-- push to last
function List:pushl(value)
    if value == nil or self:contains(value) then
        return false
    end
    self._prev[value] = self._last
    if self._last == nil then
        self._first = value
        self._last = value
    else
        self._next[self._last] = value
        self._last = value
    end
    self._value[value] = dummy
    self._count = self._count + 1
    return true
end

function List:push(value)
    if value == nil or self:contains(value) then
        return false
    end
    self._prev[value] = self._last
    if self._last == nil then
        self._first = value
        self._last = value
    else
        self._next[self._last] = value
        self._last = value
    end
    self._value[value] = dummy
    self._count = self._count + 1
    return true
end

-- remove element in list
function List:remove(value)
    if value == nil or not self:contains(value) then
        return nil
    end
    local next = self._next[value]
    local prev = self._prev[value]
    if next ~= nil then
        self._prev[next] = prev
    end
    if prev ~= nil then
        self._next[prev] = next
    end
    self._next[value] = nil
    self._prev[value] = nil
    self._value[value] = nil
    if value == self._first then
        self._first = next
    end
    if value == self._last then
        self._last = prev
    end
    self._count = self._count - 1
    return value
end

-- pop first element
function List:popf()
    return self:remove(self._first)
end

-- pop last element
function List:popl()
    return self:remove(self._last)
end

-- clear all object, free old table
function List:clear()
    self._count = 0
    self._first = nil
    self._last = nil
    self._value = {}
    self._prev = {}
    self._next = {}
end

-- with range index
function List:range(from, to)
    from = from or 1
    to = to or self._count
    if self._count <= 0 or mmin(from,to) < 1 or mmax(from,to) > self._count then
        return {}
    end
    local range = {}
    local step = (from < to) and 1 or -1    
    local idx = (step > 0) and 1 or self._count
    local value = (step > 0) and self._first or self._last
    if from > to then
        from, to = to, from
    end
    repeat
        if idx >= from and idx <= to then
            range[#range + 1] = value
        end
        idx = idx + step
        if step > 0 then
            value = self._next[value]
            if idx > to then
                break
            end
        else
            value = self._prev[value]
            if idx < from then
                break
            end
        end
    until value == nil
    return range
end

-- return nil for walk
local function _return_nil()
end

-- with element iterator
function List:walk(seq)
    if self._count <= 0 then
        return _return_nil
    end
    if seq == nil then
        seq = true
    end
    local idx = seq and 1 or self._count
    local step = seq and 1 or -1
    local value = seq and self._first or self._last
    return function()
        if value ~= nil then
            local i = idx
            local v = value
            idx = idx + step
            if seq then
                value = self._next[value]
            else           
                value = self._prev[value]
            end
            return i, v
        else
            return nil
        end
    end
end

return List