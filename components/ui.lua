local ui = {}

function ui:render_screen(ent, w, h)
  tty.clear()
  local x,y,map = ent:position()
  tty.ctm(0,0)
  -- Calculate viewport offset.
  -- x and y are the offset to add to coordinates before they go to the screen.
  -- dx and dy are the upper left corner of the rectangle on the map to render.
  -- w and h are the dimensions of that rectangle.
  local screen = {
    x = 0; y = 0;
    dx = 0; y = 0;
    w = (w/2):floor(); h = h;
  }
  map:render_screen(screen, x, y)
  tty.ctm((w/2+1):floor(),0)
  local log = game.getLog()
  for i=1,h do
    local line = (log[#log-i+1] or ""):sub(1, (w/2):floor())
    tty.put(0,i,"│"..line)
  end
  tty.ctm(0,0)
  tty.move(x+screen.dx,y+screen.dy)
  tty.flip()
end

return ui
