require 'util'
require 'Object'
require 'settings'
require 'game'
require 'ui'
require 'dredmor'

if not love then
  require 'tty'
  require 'lovecompat'
else
  error 'running under love2d is not yet supported'
  love.readkey = function() end
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
    return
  end

  math.randomseed(flags.parsed.seed)
  os.execute("mkdir -p '%s'" % flags.parsed.config_dir)
  settings.load()
  dredmor.loadAll()

  if flags.parsed.load then
    game.load(flags.parsed.load)
  else
    game.new('test')
  end

  ui.init()

  turn = coroutine.wrap(turn)
end

function love.draw()
  ui.draw()
end

local state = 0
local keybuffer = {}

function love.keypressed(key)
  table.insert(keybuffer, key)
end

function love.update(t)
  local _
  if state == 'key' then
    -- get a key from the keybuffer, and pass it to the main thread
    -- if the keybuffer is empty, just sleep briefly and return
    love.readkey(keybuffer)
    if #keybuffer > 0 then
      state = turn(table.remove(keybuffer, 1))
    else
      log.debug('sleeping')
      love.timer.sleep(0.033)
    end
  else
    -- state is a delay; decrement it and then resume
    state = state - t
    if state <= 0 then
      state = turn()
    end
  end
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
