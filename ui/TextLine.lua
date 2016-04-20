-- A UI widget for a single line of (possibly styled) text.
local Window = require 'ui.Window'
local TextLine = Window:subclass {}

function TextLine:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.text, 'TextLine created without text')
end

function TextLine:__tostring()
  return 'TextLine[%s]' % self.text
end

function TextLine:getSize()
  return #self.text,1
end

function TextLine:render()
  tty.style('o')
  if self.colour then tty.colour(unpack(self.colour)) end
  if self.style then tty.style(self.style) end
  if self.focused == true then tty.style('v') end
  tty.put(0, 0, self.text)
end

return TextLine
