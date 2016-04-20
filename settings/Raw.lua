-- A "raw" setting. This is used for settings that have their own editing interface,
-- like the keybinds. It has a no-args constructor and no validation of any kind.

-- It is also a valid TreeNode, implementing the :activate and :label methods.
local Raw = ui.TextLine:subclass {
  text = 'placeholder';
}

function Raw:__init(data)
  local category = settings.categories[data.category]
  ui.TextLine.__init(self, data)
  self.text = self:label()
  settings.register(self.category, self)
end

function Raw:label(width)
  return '%s%s[%s]' % { self.name, ' ', tostring(self.value) }
end

function Raw:activate(tree)
  self:set(ui.ask(self.name, tostring(self.value)) or self.value)
end

function Raw:set(val)
  self.value = val
  self.text = self:label()
  return val
end

function Raw:__call(val)
  if val == nil then
    return self.value
  else
    return self:set(val)
  end
end

return Raw
