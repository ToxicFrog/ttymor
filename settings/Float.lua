-- A float-valued setting with optional upper and lower bounds.
local Float = require('settings.Raw'):subclass {
  min = -math.huge;
  max = -math.huge;
}

function Float:set(val)
  val = tonumber(val)
  if not val then return end
  self.value = val:bound(self.min, self.max)
  return self.value
end

function Float:label()
  return '%s%s[%.2f]' % { name, ' ', self.value }
end

return Float
