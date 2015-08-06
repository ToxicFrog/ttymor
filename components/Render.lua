local Render = {
  defaults = {
    face = "?";
    colour = { 255, 255, 255, 0, 0, 0 };
    style = 'o'
  }
}

function Render:render(x, y)
  tty.style(self.Render.style)
  tty.colour(unpack(self.Render.colour))
  tty.put(x, y, self.Render.face)
end

return Render
