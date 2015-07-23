require 'util'
require 'tty'
require 'game'
require 'ecs'
require 'ui'

flags.register "help" {
  help = "This text.";
}

flags.register "load" {
  help = "Load this game immediately on game startup.";
  type = flags.string;
}

flags.register "config-dir" {
  help = "Directory to store settings and save files in.";
  type = flags.string;
  default = os.getenv('HOME')..'/.config/ttymor/';
}

local function new_game()
  game.new()

  local player = game.add {
    id = 1;
    name = "Player";
    Component "position" {};
    Component "render" { face = "@" };
    Component "control" {};
  }

  local map = game.add {
    name = "Level 1";
    Component "map" { w=100, h=100 };
  }

  map:generate()
  player:setMap(map)
  player:moveTo(10, 11)
  return player
end

function load_settings()
  if io.exists(flags.parsed.config_dir .. '/keys.cfg') then
    ui.load_bindings(flags.parsed.config_dir .. '/keys.cfg')
  end
end

function save_settings()
  ui.save_bindings(flags.parsed.config_dir .. '/keys.cfg')
end

function main(...)
  local player
  flags.parse(...)

  if flags.parsed.help then
    print(flags.help())
    return
  end

  os.execute("mkdir -p '%s'" % flags.parsed.config_dir)
  load_settings()

  if flags.parsed.load then
    game.load(flags.parsed.load)
    player = game.get(1)
  else
    player = new_game()
  end

  tty.init()
  while true do
    ui.draw(player)
    player:turn()
  end
end

function error_handler(...)
  tty.deinit()
  print(debug.traceback(..., 2))
end

function shutdown()
  tty.deinit()
  os.exit(0)
end

xpcall(main, error_handler, ...)
shutdown()
