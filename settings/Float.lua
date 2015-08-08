-- A float-valued setting with optional upper and lower bounds.
local Float = require('settings.Raw'):subclass {
  min = -math.huge;
  max = -math.huge;
}

function Float:set(val)
  val = tonumber(val)
  if not val then return end
  self.value = math.bound(self.min, val, self.max)
  return self.value
end

function Float:show()
  return '%.2f' % tostring(self.value)
end

return Float
