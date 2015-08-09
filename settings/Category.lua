local Category = Object:subclass {
  per_game = false;
}

function Category:__init(...)
  Object.__init(self, ...)
  self.settings = {}
  settings.categories[self.name] = self
  table.insert(settings.categories, self)
end

function Category:save()
  game.saveObject(
      '%s.cfg' % self.name,
      table.mapv(self.settings, f's => s.value'),
      game.name() and self.per_game)
end

function Category:load()
  local saved = game.loadOptional('%s.cfg' % self.name, game.name() and self.per_game)
  for k,v in pairs(saved or {}) do
    if self.settings[k] then
      self.settings[k].value = v
    else
      log.info('Discarding saved value for obsolete setting %s::%s',
          self.name, k)
    end
  end
end

function Category:add(setting)
  table.insert(self, setting)
  self.settings[setting.name] = setting
end

function Category:pairs()
  return pairs(table.mapv(self.settings, f's => s.value'))
end

local function node_label(self, width)
  local val = self.setting:show()
  return ' '..self.name
    ..(' '):rep(math.max(1, width - #self.name - #val))..val
end

function Category:tree()
  local node = { name = self.name }
  for _,setting in ipairs(self) do
    --;table.insert(node, setting:tree())
    table.insert(node, {
      name = setting.name;
      activate = function() setting:edit() end;
      label = node_label;
      setting = setting;
    })
  end
  return node
end

return Category
