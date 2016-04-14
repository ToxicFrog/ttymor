-- Like a TextLine, but displays an in-game entity tile and name.
local Window = require 'ui.Window'
local EntityLine = Window:subclass {
  colour = { 255, 255, 255 };
  style = 'o';
}

function EntityLine:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.content, 'EntityLine created without content')
end

function EntityLine:getSize()
  return #self.content.name+2,1
end

function EntityLine:render()
  self.content:render(0, 0)
  if self.colour then tty.colour(unpack(self.colour)) end
  if self.style then tty.style(self.style) end
  tty.put(2, 0, self.content.name)
end

return EntityLine
