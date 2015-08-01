require 'util'
require 'settings'
require 'tty'
require 'game'
require 'ui'
require 'dredmor'

local Component = require 'game.Component'

flags.register "help" {
  help = "This text.";
}

flags.register "load" {
  help = "Load this game immediately on game startup.";
  type = flags.string;
}

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
    player = game.get 'player'
  else
    player = game.new('test')
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
