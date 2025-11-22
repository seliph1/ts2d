--[CODE BY FIPS @ 4FIPS.COM, (c) 2016 FILIP STOKLAS, MIT-LICENSED]

History = {}

function History.new(max_size)
   local hist = { __index = History }
   setmetatable(hist, hist)
   hist._max_size = max_size or 10
   hist._size = 0
   hist._cursor = 1
   return hist
end

function History:push(value)
  if self._size < self._max_size then
    table.insert(self, value)
    self._size = self._size + 1
  else
    self[self._cursor] = value
    self._cursor = self._cursor % self._max_size + 1
  end
end

function History:iterator()
  local i = 0
  return function()
    i = i + 1
    if i <= self._size then
      return self[(self._cursor - i - 1) % self._size + 1]
    end
  end
end

function History:clear()
  for k = 1, self._max_size do
    self[k] = nil
  end
  self._cursor = 1
  self._size = 0
end

return History