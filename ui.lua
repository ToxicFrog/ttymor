ui = {}

function ui.draw(player)
  local w,h = tty.size()
  tty.clear()
  local x,y,map = player:position()

  -- Calculate viewport offset.
  -- x and y are the offset to add to coordinates before they go to the screen.
  -- dx and dy are the upper left corner of the rectangle on the map to render.
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
  tty.vline(map_win.x-1)
  tty.vline(log_win.x-1)

  tty.pushwin(hud_win)
  tty.colour(0, 0, 0, 255, 0, 0)
  tty.box(0, 0, hud_win.w, hud_win.h)
  tty.popwin()


  tty.pushwin(log_win)
  tty.colour(0, 0, 0, 0, 0, 255)
  tty.box(0, 0, log_win.w, log_win.h)
  tty.colour(255, 255, 255, 0, 0, 0)
  local log = game.getLog()
  for i=1,h do
    local line = (log[#log-i+1] or ""):sub(1, (w/2):floor())
    tty.put(0,i-1,line)
  end
  tty.popwin()

  tty.pushwin(map_win)
  tty.colour(0, 0, 0, 0, 255, 0)
  tty.box(0, 0, map_win.w, map_win.h)
  tty.colour(255, 255, 255, 0, 0, 0)
  --map:render_screen(x, y)
  tty.popwin()

  tty.flip()
end
