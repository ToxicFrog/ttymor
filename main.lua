require 'util'
require 'tty'
require 'game'
require 'ecs'

local player, map

if not ... then
  game.new()

  player = game.add {
    id = 1;
    name = "Player";
    Component "ui" {};
    Component "position" {};
    Component "render" { face = "@" };
  }

  map = game.add {
    name = "Level 1";
    Component "map" { w=100, h=100 };
  }

  map:generate()
  player:setMap(map)
  player:moveTo(10, 11)
else
  game.load(...)
  player = game.get(1)
  map = game.get(2)
end

function main(...)
  sw,sh = tty.init()
  while true do
    player:render_screen(sw, sh)
    local cmd = io.read(1)
    local x,y = player:position()
    if cmd == 'q' then
      game.save("test.sav")
      break
    elseif cmd == 'w' then
      player:move(0, -1)
    elseif cmd == 's' then
      player:move(0, 1)
    elseif cmd == 'a' then
      player:move(-1, 0)
    elseif cmd == 'd' then
      player:move(1, 0)
    end
  end
end

function error_handler(...)
  tty.deinit()
  print(debug.traceback(..., 2))
end

xpcall(main, error_handler, ...)
tty.deinit()
