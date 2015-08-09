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
    return coroutine.wrap(function(cat)
      for _,setting in ipairs(cat) do coroutine.yield(setting) end
    end),registered[cat]
  end
end

-- Save the listed categories to disk.
function settings.save(cat)
  if not cat then
    local success = true
    for _,cat in ipairs(registered) do
      success = success and cat:save()
    end
    return success
  else
    return registered[cat]:save()
  end
end

-- Load the listed categories. Keys not present in the file loaded will retain
-- their default value rather than becoming nil.
function settings.load(...)
  if not cat then
    for _,cat in ipairs(registered) do
      cat:load()
    end
  else
    registered[cat]:load()
  end
end

-- Display a tree containing all settings. For debugging.
-- Unlike settings.edit, this ignores all specialized methods and just yanks
-- the values out using repr().
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
  local tree = {
    name = 'Configuration';
    cancel = function()
      settings.load()
      return false
    end;
    reset = function() end;
    bindings = {
      ['key:del'] = 'reset';
    };
  }
  for _,cat in ipairs(registered) do
    table.insert(tree, cat:tree())
  end
  table.insert(tree, {
    name = "Save Configuration";
    activate = function()
      if settings.save() then
        return false
      end
    end;
  })
  table.insert(tree, {
    name = "Cancel";
    activate = tree.cancel;
  })
  ui.tree(tree)
end
