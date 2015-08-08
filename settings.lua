-- Settings management framework.
settings = {
  Raw = require 'settings.Raw';
  Int = require 'settings.Int';
  Float = require 'settings.Float';
  Category = require 'settings.Category';
  categories = {};
}

local registered = settings.categories;

flags.register "config-dir" {
  help = "Directory to store settings and save files in.";
  type = flags.string;
  default = os.getenv('HOME')..'/.config/ttymor/';
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

-- Register the given key in the given category. Returns an accessor for that key.
-- Safe to use in multiple files, but asserts if the defaults don't match.
function settings.register(cat, key, setting)
  assert_registered(cat)
  if registered[cat].settings[key] then
    assertf(setting.value == registered[cat].settings[key].value,
      "multiple registrations of configuration key %s::%s with conflicting default values %s ~= %s",
      cat, key, registered[cat].settings[key].value, setting.value)
  else
    registered[cat]:add(setting)
  end
  return settings.accessor(cat, key)
end

-- Return an accessor for an existing key.
function settings.accessor(cat, key)
  local setting = assert_registered(cat, key)
  return function(val)
    if val ~= nil then
      setting.value = val
    end
    return setting.value
  end
end

-- Get the current value. If key is unspecified, returns the entire table for
-- that category.
function settings.get(cat, key)
  local setting = assert_registered(cat, key)
  if key then
    return setting.value
  else
    return table.mapv(setting.settings, f's => s.value')
  end
end

-- Iterate over all (key,value) settingpairs in a category.
function settings.pairs(cat)
  cat = assert_registered(cat)
  return cat:pairs()
end

-- Save the listed categories to disk.
function settings.save(...)
  local args = {...}
  if #args == 0 then
    return settings.save(unpack(table.keys(registered)))
  end

  for _,cat in ipairs(args) do
    registered[cat]:save()
  end
end

-- Load the listed categories. Keys not present in the file loaded will retain
-- their default value rather than becoming nil.
function settings.load(...)
  local args = {...}
  if #args == 0 then
    return settings.load(unpack(table.keys(registered)))
  end

  for _,cat in ipairs(args) do
    registered[cat]:load()
  end
end

-- Display a tree containing all settings. For debugging. Will eventually be
-- fleshed out into a settings editor.
function settings.show()
  local tree = { name = "Settings Debug View" }
  for _,cat in ipairs(registered) do
    local node = { name = cat.name }
    for _,setting in ipairs(cat) do
      table.insert(node, {
        name = '%s = %s' % { setting.name, repr(setting.value):gsub('%s+', ' ') }
      })
    end
    table.insert(tree, node)
  end
  ui.tree(tree)
end

function settings.edit()
  local tree = { name = 'Configuration' }
  for _,cat in ipairs(registered) do
    table.insert(tree, cat:tree())
  end
  table.insert(tree, {
    name = "Save Configuration";
    activate = function() settings.save() return false end;
  })
  table.insert(tree, {
    name = "Cancel";
    activate = function() settings.load() return false end;
  })
  ui.tree(tree)
end
