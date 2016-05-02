-- Like a TextLine, but displays an in-game entity tile and name.
local Window = require 'ui.Window'
local EntityLine = Window:subclass {
  can_focus = true;
}

function EntityLine:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.entity, 'EntityLine created without content')
end

function EntityLine:__tostring()
  return 'EntityLine[%s]' % tostring(self.entity)
end

function EntityLine:requestSize()
  self.w,self.h = #self.entity.name+2,1
end

function EntityLine:finalizeSize() end

-- HACK HACK HACK
-- This gets called only after the parent's size is finalized, which means we
-- now know what size to expand to.
function EntityLine:finalizePosition(...)
  ui.Window.finalizePosition(self, ...)
  self.w = self.parent:getChildBB().w
end

function EntityLine:render()
  tty.push { x = 0; y = 0; w = 1; h = 1; }
  self.entity:render(0, 0)
  tty.pop()
  tty.style(self.focused and 'v' or 'V')
  tty.put(2, 0, self.entity.name)
end

return EntityLine
