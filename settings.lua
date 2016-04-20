-- Settings management framework.
require 'Object'
local Tree = require 'ui.Tree'

flags.register "config-dir" {
  help = "Directory to store settings and save files in.";
  type = flags.string;
  default = os.getenv('HOME')..'/.config/ttymor/';
}

settings = {
  Raw = require 'settings.Raw';
  Int = require 'settings.Int';
  Float = require 'settings.Float';
  Category = require 'settings.Category';
  categories = {};
}

setmetatable(settings, { __index = settings.categories })
local registered = settings.categories;

settings.tree = {
  title = "Configuration";
  cancel = function(self)
    settings.load()
    self:detach()
  end;
  key_del = function(self)
    if self:focused().reset then
      self:focused():reset()
    end
    return true
  end;
}

local function assert_registered(cat, key)
  assertf(registered[cat],
    "attempt to access unregistered configuration category %s", cat)
  if key then
    return assertf(registered[cat].settings[key],
      "attempt to access unregistered configuration key %s::%s", cat, key)
  else
    return registered[cat]
  end
end

-- Register the given setting in the given category.
function settings.register(cat, setting)
  assert_registered(cat)
  registered[cat]:add(setting)
end

-- Get the current value. If key is unspecified, returns the entire table for
-- that category.
function settings.get(cat, key)
  local setting = assert_registered(cat, key)
  if key then
    return setting.value
  else
    return coroutine.wrap(function(cat)
      for setting in cat:settings() do
        coroutine.yield(setting)
      end
    end),registered[cat]
  end
end

-- Save the listed categories to disk.
function settings.save(cat)
  if not cat then
    local success = true
    for _,cat in ipairs(registered) do
      if cat.save then
        success = success and cat:save()
      end
    end
    return success
  else
    return registered[cat]:save()
  end
end

-- Load the listed categories. Keys not present in the file loaded will retain
-- their default value rather than becoming nil.
function settings.load(cat)
  if not cat then
    for _,cat in ipairs(registered) do
      if cat.save then
        cat:load()
      end
    end
  else
    registered[cat]:load()
  end
end

-- Display a tree containing all settings. For debugging.
-- Unlike settings.edit, this ignores all specialized methods and just yanks
-- the values out using repr().
function settings.show()
  local tree = { title = "Settings Debug View" }
  for _,cat in ipairs(registered) do
    local node = { text = cat.name }
    for setting in cat:settings() do
      table.insert(node, '%s = %s' % { setting.name, repr(setting.value):gsub('%s+', ' ') })
    end
    table.insert(tree, node)
  end
  ui.tree(tree)
end

function settings.edit()
  local tree = { title = "Configuration" }
  for _,cat in ipairs(registered) do
    table.insert(tree, cat)
  end
  table.insert(tree, ui.TextLine {
    text = "Save Configuration";
    activate = function(self, tree)
      if settings.save() then
        tree:cancel()
      end
    end;
  })
  table.insert(tree, ui.TextLine {
    text = "Cancel";
    activate = function(self, tree) tree:cancel() end;
  })
  ui.tree(tree)
end
