-- A "raw" setting. This is used for settings that have their own editing interface,
-- like the keybinds. It has a no-args constructor and no validation of any kind.
-- Attempting to show() it is an error.
local Raw = Object:subclass {}

function Raw:show()
  errorf('Attempt to :show() a Raw setting %s', self.name)
end

function Raw:set(val)
  self.value = val
  return val
end

function Raw:__call(val)
  if val == nil then
    return self.value
  else
    return self:set(val)
  end
end

function Raw:__init(...)
  Object.__init(self, ...)
  settings.register(self.category, self.name, self)
end

return Raw
