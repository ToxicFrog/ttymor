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
    w = w; h = h;
  }
  map:render_screen(screen, x, y)
  tty.move(x+screen.dx,y+screen.dy)
  tty.ctm(0,0)
  tty.flip()
end

return ui
