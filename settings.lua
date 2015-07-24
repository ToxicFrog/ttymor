-- Settings management framework.
settings = {}

local repr = require('repr').repr
local registered = {}

flags.register "config-dir" {
  help = "Directory to store settings and save files in.";
  type = flags.string;
  default = os.getenv('HOME')..'/.config/ttymor/';
}

local function assert_registered(file, key)
  assert(registered[file],
    "attempt to access unregistered configuration file %s", file)
  if key then
    assert(registered[file][key] ~= nil,
      "attempt to access unregistered configuration key %s::%s", file, key)
  end
end

-- Register the given key in the given file. Returns an accessor for that key.
-- Safe to use in multiple files, but asserts if the defaults don't match.
function settings.register(file, key, default)
  if not registered[file] then
    registered[file] = {}
  end
  if registered[key] ~= nil then
    assert(default == registered[key],
      "multiple registrations of configuration key %s::%s with conflicting default values %s ~= %s",
      file, key, registered[key], default)
  else
    registered[file][key] = default
  end
  return settings.accessor(file, key)
end

-- Return an accessor for an existing key.
function settings.accessor(file, key)
  assert_registered(file, key)
  return function(val)
    if val ~= nil then
      registered[file][key] = val
    end
    return registered[file][key]
  end
end

-- Get the current value. If key is unspecified, returns an iterator over all
-- keys in the given file.
function settings.get(file, key)
  assert_registered(file, key)
  if key then
    return registered[file][key]
  else
    return pairs(registered[file])
  end
end

-- Set the current value.
function settings.set(file, key, value)
  assert_registered(file, key)
  registered[file][key] = value
end

-- Save the listed files to disk.
function settings.save(...)
  os.execute("mkdir -p '%s'" % flags.parsed.config_dir)
  local args = {...}
  if #args == 0 then
    return settings.save(unpack(table.keys(registered)))
  end

  for _,file in ipairs(args) do
    io.writefile("%s/%s.cfg" % { flags.parsed.config_dir, file },
      'return ' .. repr(registered[file]))
  end
end

-- Load the listed files. Loading is done by loading a temporary and then using
-- table.merge, so keys not present in the file loaded will retain their defaults
-- rather than becoming nil.
function settings.load(...)
  local args = {...}
  if #args == 0 then
    return settings.load(unpack(table.keys(registered)))
  end

  for _,file in ipairs(args) do
    filename = "%s/%s.cfg" % { flags.parsed.config_dir, file }
    if io.exists(filename, 'r') then
      table.merge(registered[file], loadfile(filename)())
    end
  end
end

function settings.show()
  local tree = { name = "Settings" }
  for file,keys in pairs(registered) do
    local node = { name = file }
    table.insert(tree, node)
    for key,val in pairs(keys) do
      table.insert(node, {
        name = "%s = %s" % { key, repr(val):gsub('%s+', ' ') }
      })
    end
  end
  return ui.tree(tree)
end
