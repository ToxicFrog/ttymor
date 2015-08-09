-- A "raw" setting. This is used for settings that have their own editing interface,
-- like the keybinds. It has a no-args constructor and no validation of any kind.

-- It is also a valid TreeNode, implementing the :activate and :label methods.

local Raw = Object:subclass {}

function Raw:label(width)
  local val = self:show()
  return ' '..self.name
    ..(' '):rep(math.max(1, width - #self.name - #val))..val
end

function Raw:activate()
  self:set(ui.ask(self.name, tostring(self.value)) or self.value)
end

function Raw:show()
  return '['..tostring(self.value)..']'
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
