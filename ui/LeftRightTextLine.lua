-- A UI widget for a single line of (possibly styled) text.
local Window = require 'ui.Window'
local LeftRightTextLine = Window:subclass {
  can_focus = true;
  size = { inf, 0 };
}

function LeftRightTextLine:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.left and self.right, 'LeftRightTextLine created without left/right text')
end

function LeftRightTextLine:minSize()
  return #self.left + #self.right + 1,1
end

function LeftRightTextLine:render()
  if self.focused then
    tty.style 'v'
    tty.put(0, 0, (' '):rep(self.w))
  end
  tty.put(0, 0, self.left)
  tty.put(self.w - #self.right, 0, self.right)
end

function LeftRightTextLine:cmd_update_hud()
  if self.help then
    ui.setHUD(self.text, self.help)
  end
  return true
end

return LeftRightTextLine
