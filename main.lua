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
end

function love.draw()
  ui.draw()
end

function love.update(t)
  game.get('player'):turn()
end

function love.errhand(...)
  tty.deinit()
  log.error('Fatal error: %s', debug.traceback(..., 2))
  io.stderr:write(debug.traceback(..., 2))
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
