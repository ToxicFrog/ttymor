-- A "raw" setting. This is used for settings that have their own editing interface,
-- like the keybinds. It has a no-args constructor and no validation of any kind.
--
-- Other settings inherit from this, and this is itself a subclass of TextLine;
-- it not only stores the setting data, but is used to display it as part of the
-- setting editing interface.

local Raw = ui.TextLine:subclass {
  text = '';
  w = 0;
}

function Raw:__init(data)
  local category = settings.categories[data.category]
  ui.TextLine.__init(self, data)
  self:updateText()
  settings.register(self.category, self)
end

function Raw:display()
  return '[%s]' % self.value
end

function Raw:updateText()
  local value = tostring(self:display())
  local padding = self.w - #self.name - #value + 1
  self.text = '%s%s%s' % {
    self.name, (' '):rep(padding), value
  }
end

function Raw:finalizePosition(...)
  ui.TextLine.finalizePosition(self, ...)
  self:updateText()
end

function Raw:cmd_activate(tree)
  self:set(ui.ask(self.name, tostring(self.value)) or self.value)
  return true
end

function Raw:set(val)
  self.value = val
  self:updateText()
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
