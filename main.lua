require 'util'
require 'repr'
require 'Object'
require 'ui'
require 'settings'
require 'ui.keys'
require 'game'
require 'dredmor'

if not love then
  require 'tty'
  require 'lovecompat'
else
  error 'running under love2d is not yet supported'
end

flags.register "help" {
  help = "This text.";
}

flags.register "load" {
  help = "Load this game immediately on game startup.";
  type = flags.string;
}

flags.register "seed" {
  help = "Random seed to use. Default: current time.";
  type = flags.number;
  default = os.time();
}

flags.register "log-in-game" {
  help = "Display program logs as part of the in-game log.";
  default = false;
}

local function turn()
  while true do
    local player = game.get 'player'
    xpcall(player.turn, love.errhand, player)
  end
end

function love.load(argv)
  flags.parse(unpack(argv))

  if flags.parsed.help then
    print(flags.help())
    os.exit(0)
  end

  math.randomseed(flags.parsed.seed)
  os.execute("mkdir -p '%s'" % flags.parsed.config_dir)
  settings.load()
  dredmor.loadAll()

  ui.init()

  if flags.parsed.load then
    game.load(flags.parsed.load)
  else
    game.new('test')
  end

  if flags.parsed.log_in_game then
    function log.hook(prefix, suffix)
      game.log("%s", suffix)
    end
  end

  turn = coroutine.wrap(turn)
end

function love.draw()
  ui.sendEvent(nil, 'update_hud')
  ui.draw()
end

function love.keypressed(key)
  ui.sendEvent(key, ui.keyToCommand(key))
end

function love.update(t)
  love.timer.sleep(0.033 - t)
  ui.sendEvent(nil, 'update')
end

function love.errhand(...)
  tty.deinit()
  log.error('Fatal error: %s', debug.traceback(..., 2))
  os.exit(1) -- die without saving settings
end

function love.quit()
  tty.deinit()
  settings.save()
end

if love.main then
  -- We're running in compatibility mode, not inside actual love2d
  -- Call the main function provided by lovecompat
  return love.main(...)
end
-- Otherwise we just return and love2d handles setting up the mainloop.
