-- An enum setting with multiple possible string values
local Raw = require 'settings.Raw'
local Enum = Raw:subclass {}

function Enum:__init(data)
  Raw.__init(self, data)
  self:set(self.value) -- causes validation to occur
end

function Enum:set(value)
  Raw.set(self, value)
  self.help = self.helps[self.value]
end

function Enum:cmd_activate()
  local index
  for i,v in ipairs(self.values) do
    if self.value == v then index = i+1; break end
  end
  if index > #self.values then index = 1 end
  self:set(self.values[index])
  return true
end

return Enum
