-- An integer-valued setting with optional upper and lower bounds.
local Int = require('settings.Raw'):subclass {
  min = -math.huge;
  max = -math.huge;
}

function Int:set(val)
  val = tonumber(val)
  if not val then return end
  self.value = math.bound(self.min, val, self.max):floor()
  return self.value
end

function Int:show()
  return tostring(self.value)
end

return Int
