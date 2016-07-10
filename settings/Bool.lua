-- A boolean on/off setting
local Bool = require('settings.Raw'):subclass {}

function Bool:display()
  return '[%s]' % (self.value and 'Y' or ' ')
end

function Bool:cmd_activate()
  self:set(not self.value)
  return true
end

return Bool
