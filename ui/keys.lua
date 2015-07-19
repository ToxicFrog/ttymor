local bindings = {} -- key -> command map
local settings = {} -- command -> keys map

local defaults = {
  up = 'W';
  down = 'S';
  left = 'A';
  right = 'D';
  ascend = '<';
  descend = '>';
  menu = 'esc';
  quit = 'Q';
  enter = 'enter';
}

local function install_bindings(settings)
  bindings = {}
  for command,key in pairs(settings) do
    assert(not bindings[key], "multiple binding for key "..key)
    bindings[key] = command
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

function ui.load_default_bindings()
  install_bindings(defaults)
end

ui.load_default_bindings()
