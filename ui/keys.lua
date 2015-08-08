settings.Category {
  name = 'Keybinds';
}

local bindings = {} -- key -> command map

function ui.readkey()
  tty.flip()
  local key = tty.readkey()
  return bindings[key] or 'key:'..key
end

-- Keybinding validation.
-- Checks that all critical keys are bound, and that no key is bound to more than
-- one command.
function ui.validate_bindings()
  local errors = {}
  local map = settings.get('Keybinds')

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

function ui.update_bindings()
  bindings = {}
  for command,keys in settings.pairs('Keybinds') do
    for _,key in ipairs(keys) do
      assert(not bindings[key], "multiple binding for key "..key)
      bindings[key] = command
    end
  end
end

--
-- Everything below this line is related to loading the default keybinds and the
-- key remapping UI elements from ui.key_defaults
--

local KeyCommand = {}

function KeyCommand:activate()
  local width = #self.name+4;
  ui.box(ui.centered(width, 3), self.name)
  tty.flip()
  local key = tty.readkey()
  if key == self.keys()[1] then return end
  self.keys { key, self.keys()[1] }
end

function KeyCommand:clear()
  self.keys {}
end

function KeyCommand:label(width)
  local keys = '[%6s][%6s]' % {
    (self.keys()[1] or '---'),
    (self.keys()[2] or '---'),
  }
  return ' '..self.name .. (' '):rep(math.max(1, width - #self.name - #keys)) .. keys
end

local function update_if(self)
  local r,e = ui.validate_bindings()
  if not r then
    tty.colour(255, 0, 0, 0, 0, 0)
    ui.message('Error', e)
    return
  end
  ui.update_bindings()
  settings.save('keys')
  return r
end

local default_tree = require 'ui.key_defaults'
default_tree.name = "Keybinds"
default_tree.bindings = {
  ['key:del'] = 'clear';
}
function default_tree:cancel(self)
  -- revert to defaults
  settings.load('keys')
  ui.update_bindings()
  return false
end

for _,category in ipairs(default_tree) do
  for _,command in ipairs(category) do
    command.keys = settings.register('Keybinds', command.command, {
      name = command.command;
      value = command.keys;
    })
    table.merge(command, KeyCommand, 'error')
  end
end
table.insert(default_tree, {
  name = "Apply Settings";
  activate = update_if;
})
table.insert(default_tree, {
  name = "Cancel";
  activate = function(self) return self._tree:cancel() end;
})

ui.update_bindings()

function ui.keybinds_screen()
  ui.tree(default_tree)
end
