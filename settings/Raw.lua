-- A "raw" setting. This is used for settings that have their own editing interface,
-- like the keybinds. It has a no-args constructor and no validation of any kind.
-- Attempting to show() it is an error.
local Raw = Object:subclass {}

function Raw:show()
  return '['..tostring(self.value)..']'
end

function Raw:set(val)
  self.value = val
  return val
end

function Raw:edit()
  -- 'Readonly' doesn't mean it can't be changed ever, but does mean it can't
  -- be changed from the normal settings UI. This is used for (e.g.) settings
  -- that are set at character creation time and then can't be changed, like
  -- map size.
  if self.readonly then return end
  self:set(ui.ask(self.name, tostring(self.value)) or self.value)
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
