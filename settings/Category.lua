local Category = Object:subclass {
  per_game = false; -- If true, will be included in the save file
  save = true; -- If false, will not be saved to disk at all
  settings = {};
}

function Category:__index(k)
  if Category[k] ~= nil then
    return Category[k]
  elseif not rawget(self, 'settings') then
    return nil
  end
  return rawget(self, 'settings')[k]()
end

function Category:__newindex(k, v)
  if rawget(self, 'settings') and self.settings[k] then
    return self.settings[k](v)
  end
  return rawset(self, k, v)
end

function Category:__init(...)
  Object.__init(self, ...)
  self.settings = {}
  settings.categories[self.name] = self
  table.insert(settings.categories, self)

  local key = self.name:gsub('[^a-zA-Z0-9_]+', '_'):lower()
  if key ~= self.name then
    if settings.categories[key] then
      errorf('fast-access key for category %s conflicts with existing category %s',
        self.name, settings.categories[key].name)
    end
    settings.categories[key] = self
  end
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
  local key = setting.name:gsub('[^a-zA-Z0-9_]+', '_'):lower()
  if key ~= setting.name then
    if self.settings[key] then
      errorf('fast-access key for setting %s::%s conflicts with existing setting %s::%s',
        self.name, setting.name, self.name, self.settings[key].name)
    end
    self.settings[key] = setting
  end
end

function Category:tree()
  if self.hidden then return nil end
  return self
end

return Category
