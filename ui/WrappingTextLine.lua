-- A UI widget for a single line of (possibly styled) text.
local TextLine = require 'ui.TextLine'
local WrappingTextLine = TextLine:subclass {
  can_focus = false;
}

function WrappingTextLine:__init(...)
  TextLine.__init(self, ...)
  self.lines = self.text:wrap(self.wrap_width)
end

function WrappingTextLine:__tostring()
  return 'WrappingTextLine[%s]' % self.text
end

function WrappingTextLine:minSize()
  local w = 0
  for i,line in ipairs(self.lines) do
    w = w:max(#line)
  end
  return w,#self.lines
end

function WrappingTextLine:render()
  for i,line in ipairs(self.lines) do
    tty.put(0,i-1,line)
  end
end

return WrappingTextLine
