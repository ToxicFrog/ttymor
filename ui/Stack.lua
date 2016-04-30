local Stack = ui.Window:subclass {}

function Stack:attach(child)
  if child and #self._children > 0 then
    self._children[#self._children].visible = false
  end
  ui.Window.attach(self, child)
end

function Stack:detach(child)
  ui.Window.detach(self, child)
  if child and #self._children > 0 then
    self._children[#self._children].visible = true
    self:layout()
  end
end

return Stack
