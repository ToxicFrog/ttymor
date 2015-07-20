ui = {}

require 'ui.tree'
require 'ui.keys'

local last_init,last_hud,last_map,last_log,last_tty,last_frame = 0,0,0,0,0,0
function ui.draw(player)
  game.log("        Log: %.3f TTY: %.3f", last_log, last_tty)
  game.log("        HUD: %.3f Map: %.3f", last_hud, last_map)
  game.log("Render: Ini: %.3f All: %.3f", last_init, last_frame)

  local t = os.clock()

  local w,h = tty.size()
  tty.colour(255, 255, 255, 0, 0, 0)
  tty.clear()
  local x,y,map = player:position()

  -- Calculate viewport offset.
  -- x and y are the offset to add to coordinates before they go to the screen.
  -- w and h are the dimensions of that rectangle.
  local hud_win = {
    x = 0; y = 0;
    w = 10; h = h;
  }
  local log_win = {
    x = w-40; y = 0;
    w = 40; h = h;
  }
  local map_win = {
    x = 11; y = 0;
    w = w-41-11; h = h;
  }

  tty.colour(255, 255, 255, 0, 0, 0)
  tty.colour(0, 0, 0, 255, 255, 255)
  ui.vline(map_win.x-1)
  ui.vline(log_win.x-1)

  last_init = os.clock()

  tty.pushwin(hud_win)
  tty.colour(0, 0, 0, 255, 0, 0)
  ui.box()
  tty.popwin()

  last_hud = os.clock()

  tty.colour(255, 255, 255, 0, 0, 0)
  tty.pushwin(log_win)
  local log = game.getLog()
  for i=1,h do
    local line = (log[#log-i+1] or ""):sub(1, (w/2):floor())
    tty.put(0,i-1,line)
  end
  tty.popwin()

  last_log = os.clock()

  tty.pushwin(map_win)
  map:render_screen(x, y)
  tty.popwin()

  last_map = os.clock()

  tty.flip()

  last_tty = os.clock()
  last_frame = last_tty - t
  last_tty = last_tty - last_map
  last_map = last_map - last_log
  last_log = last_log - last_hud
  last_hud = last_hud - last_init
  last_init = last_init - t
end

-- Draw a box with the upper left corner at (x,y)
function ui.box(rect, title)
  if not rect then
    return ui.box(tty.bounds(), title)
  end

  local w,h = tty.pushwin(rect)

  tty.put(0, 0, "┏"..("━"):rep(w-2).."┓")
  for row=1,h-2 do
    tty.put(0, row, "┃"..(" "):rep(w-2).."┃")
  end
  tty.put(0, h-1, "┗"..("━"):rep(w-2).."┛")
  if title then
    tty.put(1, 0, '┫'..title..'┣')
--    tty.put(1, 0, '╾'..title..'╼')
  end

  tty.popwin()
end

function ui.hline(row)
  local w,h = tty.size()
  tty.put(0, row, ("━"):rep(w))
end

function ui.vline(col)
  local w,h = tty.size()
  for i=1,h do
    tty.put(col, i-1, "┃")
  end
end

function ui.centered(w, h)
  local sw,sh = tty.size()
  return {
    w = w; h = h;
    x = math.floor((sw-w)/2);
    y = math.floor((sh-h)/2);
  }
end
