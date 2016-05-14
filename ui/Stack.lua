local Stack = ui.Window:subclass {}

function Stack:keyEvent(key, cmd)
  if not self.visible then return false end
  if self.can_focus and not self.focused then return false end
  local top = self._children[#self._children]
  if top and top:keyEvent(key, cmd) == true then return true end
  return self:handleEvent(key, cmd)
end

return Stack
