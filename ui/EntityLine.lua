-- Like a TextLine, but displays an in-game entity tile and name.
local Window = require 'ui.Window'
local EntityLine = Window:subclass {
  colour = { 255, 255, 255 };
  style = 'o';
  can_focus = true;
}

function EntityLine:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.entity, 'EntityLine created without content')
end

function EntityLine:__tostring()
  return 'EntityLine[%s]' % tostring(self.entity)
end

function EntityLine:getSize()
  return #self.entity.name+2,1
end

function EntityLine:render()
  self.entity:render(0, 0)
  if self.colour then tty.colour(unpack(self.colour)) end
  if self.style then tty.style(self.style) end
  tty.put(2, 0, self.entity.name)
end

return EntityLine
