--[CODE BY FIPS @ 4FIPS.COM, (c) 2016 FILIP STOKLAS, MIT-LICENSED]

History = {}

function History.new(max_size)
   local hist = { __index = History }
   setmetatable(hist, hist)
   hist.max_size = max_size or 10
   hist.size = 0
   hist.cursor = 1
   return hist
end

function History:push(value)
  if self.size < self.max_size then
    table.insert(self, value)
    self.size = self.size + 1
  else
    self[self.cursor] = value
    self.cursor = self.cursor % self.max_size + 1
  end
end

function History:iterator()
  local i = 0
  return function()
    i = i + 1
    if i <= self.size then
      return self[(self.cursor - i - 1) % self.size + 1]
    end
  end
end

return History