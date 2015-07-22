local bindings = {} -- key -> command map
local settings = {} -- command -> keys map

local function install_bindings(settings)
  bindings = {}
  for command,keys in pairs(settings) do
    for _,key in ipairs(keys) do
      assert(not bindings[key], "multiple binding for key "..key)
      bindings[key] = command
    end
  end
end

function ui.readkey()
  tty.flip()
  local key = tty.readkey()
  return bindings[key] or 'key:'..key
end

function ui.load_bindings(path)
  return install_bindings(loadfile(path)())
end

local KeyCommand = {}

local repr = require('repr').repr
function KeyCommand:binds()
  if not self._tree.keybinds[self.command] then
    error("can't find binding entry: %s %s\n%s" % { self.command, repr(self._tree.keybinds), repr(settings) })
  end
  return self._tree.keybinds[self.command]
end

function KeyCommand:activate()
  local width = #self.name+4;
  ui.box(ui.centered(width, 3), self.name)
  tty.flip()
  local key = tty.readkey()
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
    settings = self._tree.keybinds
    install_bindings(settings)
    return true
  end;
})
table.insert(default_tree, {
  name = "Cancel";
  activate = function(self) return false end;
})

install_bindings(settings)

function ui.keybinds_screen()
  default_tree.keybinds = table.copy(settings)
  ui.tree(default_tree)
  game.log("--- new keybinds ---")
  for command,keys in pairs(settings) do
    game.log("%s: %s, %s", command, keys[1], keys[2])
  end
  game.log("--- end ---")
end
