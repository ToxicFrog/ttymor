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

settings.tree = Tree {
  title = "Configuration";
  visible = true;
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

-- Register the given key in the given category.
function settings.register(cat, key, setting)
  assert_registered(cat)
  if registered[cat].settings[key] then
    error(
      "multiple registrations of configuration key %s::%s with conflicting default values %s ~= %s",
      cat, key, registered[cat].settings[key].value, setting.value)
  else
    registered[cat]:add(setting)
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
function settings.load(...)
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
  if not settings.tree.constructed then
    -- We defer adding these nodes so that they occur at the bottom of the
    -- settings list.
    settings.tree.root:addNode {
      name = "Save Configuration";
      activate = function(self)
        if settings.save() then
          self.tree:cancel()
        end
      end;
    }
    settings.tree.root:addNode {
      name = "Cancel";
      activate = function(self) return self.tree:cancel() end;
    }
    settings.tree.constructed = true
  end
  ui.main_win:attach(settings.tree)
  ui.layout()
  settings.tree:set_focus(1)
end
