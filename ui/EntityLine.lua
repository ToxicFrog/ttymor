-- Like a TextLine, but displays an in-game entity tile and name.
local Window = require 'ui.Window'
local EntityLine = Window:subclass {
  can_focus = true;
  -- cmd_activate will emit this verb if set
  default_verb = nil;
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

function EntityLine:cmd_any(key, cmd)
  local verb = cmd:match('verb_(.*)')
  if not verb then return false end

  game.get('player'):verb(verb, self.entity)
  return true
end

function EntityLine:cmd_activate(key, cmd)
  if not self.default_verb then
    return ui.Window.handleEvent(self.entity, key, cmd)
  end
  game.get('player'):verb(self.default_verb, self.entity)
  return true
end

return EntityLine
