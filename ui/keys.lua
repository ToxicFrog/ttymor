local bindings = {} -- key -> command map

function ui.readkey()
  tty.flip()
  local key = tty.readkey()
  return bindings[key] or 'key:'..key
end

local function set(...)
  local R = {}
  for _,v in ipairs {...} do R[v] = true end
  return R
end

-- Keybinding validation.
-- Checks that all critical keys are bound, and that no key is bound to more than
-- one command.
function ui.validate_bindings()
  local errors = {}
  local critical = set('activate', 'cancel', 'up', 'down', 'left', 'right')

  local seen = {}
  for setting in settings.get('Keybinds') do
    if critical[setting.command] and #setting() == 0 then
      table.insert(errors, 'Critical command [%s] is unbound' % setting.command)
    else
      for _,key in ipairs(setting()) do
        if seen[key] then
          table.insert(errors, 'Key [%s] is bound to both [%s] and [%s]' % {
            key, seen[key].command, setting.command })
        else
          seen[key] = setting
        end
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
  for setting in settings.get('Keybinds') do
    for _,key in ipairs(setting()) do
      bindings[key] = setting.command
    end
  end
end

--
-- Everything below this line is related to loading the default keybinds and the
-- key remapping UI elements from ui.key_defaults
--
local keybind_tree = require 'ui.key_defaults'
keybind_tree.name = 'Keybinds'

settings.Category {
  name = 'Keybinds';
  tree = function(self)
    return keybind_tree
  end;
  save = function(self)
    local r,e = ui.validate_bindings()
    if not r then
      e.colour = { 255, 0, 0 }
      e.readonly = true
      table.insert(e, '')
      table.insert(e, 'Keybinds not saved.')
      ui.message('Error', e)
      return false
    end
    ui.update_bindings()
    return settings.Category.save(self)
  end;
  load = function(self)
    settings.Category.load(self)
    ui.update_bindings()
  end;
}

local KeySetting = settings.Raw:subclass {}

function KeySetting:show()
  return '[%6s][%6s]' % {
    self.value[1] or '------',
    self.value[2] or '------',
  }
end

function KeySetting:activate()
  local width = #self.name+4;
  ui.box(ui.centered(width, 3), self.name)
  tty.flip()
  local key = tty.readkey()
  if key == self.value[1] then return end
  self:set { key, self.value[1] }
end

function KeySetting:reset()
  self:set {}
end

for _,category in ipairs(keybind_tree) do
  for i,command in ipairs(category) do
    category[i] = KeySetting {
      category = 'Keybinds';
      name = command.name;
      command = command.command;
      value = command.keys;
    }
  end
end

ui.update_bindings()
