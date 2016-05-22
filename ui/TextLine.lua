-- A UI widget for a single line of (possibly styled) text.
local Window = require 'ui.Window'
local TextLine = Window:subclass {
  can_focus = true;
}

function TextLine:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.text, 'TextLine created without text')
end

function TextLine:__tostring()
  return 'TextLine[%s]' % self.text
end

function TextLine:requestSize()
  self.w,self.h = #self.text,1
end

function TextLine:finalizeSize() end

-- HACK HACK HACK
-- This gets called only after the parent's size is finalized, which means we
-- now know what size to expand to.
function TextLine:finalizePosition(...)
  ui.Window.finalizePosition(self, ...)
  self.w = self.parent:getChildBB().w
end

function TextLine:render()
  if self.focused then
    tty.style 'v'
    tty.put(0, 0, (' '):rep(self.w))
  end
  tty.put(0, 0, self.text)
end

function TextLine:cmd_update_hud()
  if self.help then
    ui.setHUD(self.text, self.help)
  end
  return true
end

return TextLine
