local Node = require 'ui.Node'
local Category = Node:subclass {
  per_game = false; -- If true, will be included in the save file
  save = true; -- If false, will not be saved to disk at all
  hidden = false; -- If true, won't show up in the settings UI
  settings = {};
}

function Category:__index(k)
  if Category[k] ~= nil then
    return Category[k]
  elseif rawget(self, 'settings') and self.settings[k] then
    return self.settings[k]()
  end
end

function Category:__newindex(k, v)
  if rawget(self, 'settings') and self.settings[k] then
    return self.settings[k](v)
  end
  return rawset(self, k, v)
end

function Category:__init(...)
  Node.__init(self, settings.tree, settings.tree.root, ...)
  self.settings = {}
  settings.categories[self.name] = self
  table.insert(settings.categories, self)

  if not self.hidden then
    table.insert(settings.tree.root, self)
  end

  local key = self.name:gsub('[^a-zA-Z0-9_]+', '_'):lower()
  if key ~= self.name then
    if settings.categories[key] then
      error('fast-access key for category %s conflicts with existing category %s',
        self.name, settings.categories[key].name)
    end
    settings.categories[key] = self
  end
end

function Category:save()
  log.info('Saving configuration file %s.cfg', self.name)
  return game.saveObject(
      '%s.cfg' % self.name,
      table.mapv(self.settings, f's => s.value'),
      game.name() and self.per_game)
end

function Category:load()
  log.info('Loading configuration file %s.cfg', self.name)
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
  self.w = self.w:max(setting.w)
  self.h = self.h + 1

  local key = setting.name:gsub('[^a-zA-Z0-9_]+', '_'):lower()
  if key ~= setting.name then
    if self.settings[key] then
      error('fast-access key for setting %s::%s conflicts with existing setting %s::%s',
        self.name, setting.name, self.name, self.settings[key].name)
    end
    self.settings[key] = setting
  end
end

return Category
