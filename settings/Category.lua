--
-- A category of game settings.
-- This inherits from Expander so that it can be included directly in the
-- settings edit tree.
--
local Category = ui.Expander:subclass {
  per_game = false; -- If true, will be included in the save file
  save = true; -- If false, will not be saved to disk at all
  hidden = false; -- If true, won't show up in the settings UI
  _settings = {};
}

function Category:__tostring()
  return 'Category[%s]' % self.name
end

function Category:__index(k)
  if Category[k] ~= nil then
    return Category[k]
  elseif rawget(self, 'settings') and self._settings[k] then
    -- category.foo is equivalent to category.settings.foo(), i.e. it returns
    -- the value of that setting.
    return self._settings[k]()
  end
end

function Category:__newindex(k, v)
  if rawget(self, 'settings') and self._settings[k] then
    -- Similar to the above, setting a field on a category calls the setter for
    -- that setting if it exists.
    return self._settings[k](v)
  end
  return rawset(self, k, v)
end

function Category:__init(init)
  init.text = init.name
  init.content = ui.VList { name = "Category[%s]$internalList" % init.name }
  init._settings = {}
  ui.Expander.__init(self, init)
  settings.categories[self.name] = self
  table.insert(settings.categories, self)

  local key = self.name:gsub('[^a-zA-Z0-9_]+', '_'):lower()
  if key ~= self.name then
    if settings.categories[key] then
      error('fast-access key for category %s conflicts with existing category %s',
        self.name, settings.categories[key].name)
    end
    settings.categories[key] = self
  end
end

function Category:settings()
  return self.content:children()
end

function Category:save()
  log.info('Saving configuration file %s.cfg', self.name)
  return game.saveObject(
      '%s.cfg' % self.name,
      table.mapv(self._settings, f's => s.value'),
      game.name() and self.per_game)
end

function Category:load()
  log.info('Loading configuration file %s.cfg', self.name)
  local saved = game.loadOptional('%s.cfg' % self.name, game.name() and self.per_game)
  for k,v in pairs(saved or {}) do
    if self._settings[k] then
      log.debug('Setting %s=%s', k, repr(v))
      self._settings[k].value = v
    else
      log.info('Discarding saved value for obsolete setting %s::%s',
          self.name, k)
    end
  end
end

function Category:add(setting)
  assertf(not self._settings[setting.name],
    "multiple registrations of configuration key %s.%s", self.name, setting.name)
  self._settings[setting.name] = setting

  local key = setting.name:gsub('[^a-zA-Z0-9_]+', '_'):lower()
  if key ~= setting.name then
    assertf(not self._settings[key],
      'fast-access key for setting %s.%s conflicts with existing setting %s.%s',
      self.name, setting.name, self.name, (self._settings[key] or {}).name)
    self._settings[key] = setting
  end

  self.content:attach(setting)
end

return Category
