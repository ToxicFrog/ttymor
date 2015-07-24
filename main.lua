require 'util'
require 'settings'
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

local function new_game()
  game.new()

  local player = game.add {
    id = 1;
    name = "Player";
    Component "position" {};
    Component "render" { face = "@"; style = 'v'; };
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

function main(...)
  local player
  flags.parse(...)

  if flags.parsed.help then
    print(flags.help())
    return
  end

  settings.load()

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
  os.exit(1) -- die without saving settings
end

function shutdown()
  tty.deinit()
  settings.save()
  os.exit(0)
end

xpcall(main, error_handler, ...)
shutdown()
