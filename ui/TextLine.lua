-- A UI widget for a single line of (possibly styled) text.
local Window = require 'ui.Window'
local TextLine = Window:subclass {}

function TextLine:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.content, 'TextLine created without content')
end

function TextLine:getSize()
  return #self.content,1
end

function TextLine:render()
  if self.colour then tty.colour(unpack(self.colour)) end
  if self.style then tty.style(self.style) end
  tty.put(0, 0, self.content)
end

return TextLine
