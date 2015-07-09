local render = {}

function render:render(ent, view)
  print("render", ent)
  local x,y = ent:position()
  tty.put(x + view.dx, y + view.dy, self.face or "?")
end

return render
