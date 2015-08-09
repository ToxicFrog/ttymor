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
  return game.saveObject(
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

function Category:tree()
  return self
end

return Category
