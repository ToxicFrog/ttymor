local render = {}

function render:render(ent, view)
  local x,y = ent:position()
  tty.put(x + view.dx, y + view.dy, self.face or "?")
end

return render
