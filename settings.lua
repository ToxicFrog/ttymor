-- Settings management framework.
require 'Object'
local Tree = require 'ui.Tree'

flags.register "config-dir" {
  help = "Directory to store settings and save files in.";
  type = flags.string;
  default = os.getenv('HOME')..'/.config/ttymor/';
}

settings = {
  Bool = require 'settings.Bool';
  Enum = require 'settings.Enum';
  Float = require 'settings.Float';
  Int = require 'settings.Int';
  Key = require 'settings.Key';
  Raw = require 'settings.Raw';
  Category = require 'settings.Category';
  categories = {};
}

setmetatable(settings, { __index = settings.categories })
local registered = settings.categories;

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
    if not cat.hidden then
      table.insert(tree, cat)
    end
  end
  table.insert(tree, ui.TextLine {
    text = "Save Configuration";
    cmd_activate = function()
      if settings.save() then
        ui.sendEvent(nil, 'cancel')
      end
      return true
    end;
  })
  table.insert(tree, ui.TextLine {
    text = "Cancel";
    cmd_activate = function()
      ui.sendEvent(nil, 'cancel')
      return true
    end;
  })
  function tree:cmd_cancel()
    -- revert to old settings
    settings.load()
    for _,cat in ipairs(registered) do
      if not cat.hidden then cat:detach() end
    end
    return ui.Tree.cmd_cancel(self)
  end
  ui.tree(tree)
end
