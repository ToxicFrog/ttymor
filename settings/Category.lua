local Category = {
  per_game = false;
}
Category.__index = Category

-- Save
function Category:save()
  game.saveObject(
      '%s.cfg' % self.name,
      table.mapv(self.settings, f's => s.value'),
      self.per_game)
end

function Category:load()
  local saved = game.loadOptional('%s.cfg' % self.name, self.per_game)
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

function Category:tree()
  local node = { name = self.name }
  for _,setting in ipairs(self) do
    --;table.insert(node, setting:tree())
    table.insert(node, {
      name = '%s = %s' % { setting.name, repr(setting.value):gsub('%s+', ' ') }
    })
  end
  return node
end

return function(name)
  return setmetatable({name = name, settings = {}}, Category)
end
