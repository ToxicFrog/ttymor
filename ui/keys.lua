local repr = require('repr').repr

local bindings = {} -- key -> command map
local settings = {} -- command -> keys map

function ui.readkey()
  tty.flip()
  local key = tty.readkey()
  return bindings[key] or 'key:'..key
end

-- Keybinding validation.
-- Checks that all critical keys are bound, and that no key is bound to more than
-- one command.
function ui.validate_bindings(map)
  local errors = {}
  for _,command in ipairs { 'activate', 'cancel', 'up', 'down', 'left', 'right' } do
    if #map[command] == 0 then
      table.insert(errors, 'Critical command <%s> is unbound' % command)
    end
  end
  local seen = {}
  for command,keys in pairs(map) do
    for _,key in ipairs(keys) do
      if seen[key] then
        table.insert(errors, 'Key <%s> is bound to both <%s> and <%s>' % { key, seen[key], command })
      else
        seen[key] = command
      end
    end
  end
  if #errors > 0 then
    return nil,errors
  else
    return true
  end
end

function ui.install_bindings(map)
  local r,e = ui.validate_bindings(map)
  if not r then
    return nil,e
  end

  bindings = {}
  for command,keys in pairs(map) do
    for _,key in ipairs(keys) do
      assert(not bindings[key], "multiple binding for key "..key)
      bindings[key] = command
    end
  end
  settings = map
  return true
end

function ui.load_bindings(path)
  return ui.install_bindings(loadfile(path)())
end

function ui.save_bindings(path)
  return io.writefile(path, 'return '..repr(settings))
end

--
-- Everything below this line is related to loading the default keybinds and the
-- key remapping UI elements from ui.key_defaults
--

local KeyCommand = {}

function KeyCommand:binds()
  return self._tree.keybinds[self.command]
end

function KeyCommand:activate()
  local width = #self.name+4;
  ui.box(ui.centered(width, 3), self.name)
  tty.flip()
  local key = tty.readkey()
  if key == self:binds()[1] then return end
  self:binds()[2] = self:binds()[1]
  self:binds()[1] = key
end

function KeyCommand:clear()
  self._tree.keybinds[self.command] = {}
end

function KeyCommand:label(width)
  local keys = '[%6s][%6s]' % {
    (self:binds()[1] or '---'),
    (self:binds()[2] or '---'),
  }
  return ' '..self.name .. (' '):rep(math.max(1, width - #self.name - #keys)) .. keys
end

local default_tree = require 'ui.key_defaults'
default_tree.name = "Keybinds"
default_tree.bindings = {
  ['key:del'] = 'clear';
}
for _,category in ipairs(default_tree) do
  for _,command in ipairs(category) do
    settings[command.command] = command.keys
    command.keys = nil
    table.merge(command, KeyCommand, 'error')
  end
end
table.insert(default_tree, {
  name = "Apply Settings";
  activate = function(self)
    local r,e = ui.install_bindings(self._tree.keybinds)
    if not r then
      tty.colour(255, 0, 0, 0, 0, 0)
      ui.message('Error', e)
    else
      return true
    end
  end;
})
table.insert(default_tree, {
  name = "Cancel";
  activate = function(self) return false end;
})

ui.install_bindings(settings)

function ui.keybinds_screen()
  default_tree.keybinds = table.copy(settings)
  ui.tree(default_tree)
end
