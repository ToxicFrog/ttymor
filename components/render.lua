local render = {
  face = "?";
  colour = { 255, 255, 255, 0, 0, 0 };
  style = 'o'
}

function render:render(ent, x, y)
  tty.style(self.style)
  tty.colour(unpack(self.colour))
  tty.put(x, y, self.face)
end

return render
