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

function TextLine:render()
  tty.style(self.focused and 'v' or 'V')
  tty.put(0, 0, self.text)
end

return TextLine
