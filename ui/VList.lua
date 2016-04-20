--
-- Does not directly support things like subtrees or focus.
--
local Window = require 'ui.Window'

local VList = Window:subclass {
  size = { 0, 0 };
  position = { -1, -1 };
}

function VList:__init(data)
  Window.__init(self, data)
  self:clear()
end

function VList:__tostring()
  return 'VList'
--  return 'VList[%s|%d]' % { self, #self._children }
end

function VList:getChildSize()
  w = 0
  h = 0
  for child in self:children() do
    w = w:max(child.w)
    h = h + child.h
  end
  return w,h
end

-- FIXME: if we're not visible, this ends extremely poorly; Window.layout returns
-- without doing anything, and then we try to arrange our children, which haven't
-- been laid out at all, and everything goes horribly wrong
function VList:layout(w, h)
  Window.layout(self, w, h)
  if not self.visible then return end
  -- Override the default child positioning loop to lay them out top to bottom
  -- rather than back to front.
  local y = 0
  for child in self:children() do
    if child.visible then
      log.debug("VList:reposition: %s (%s)", child, child.layout)
      child.y = y
      y = y + child.h
      log.debug("VList:reposition: %s: %d,%d", child.name, child.x, child.y)
    end
  end
end

function VList:renderSlice(x, y, w, h)
  local real_y = 0
  for child in self:children() do
    -- render child only if it is entirely inside the slice
    -- FIXME: call renderSlice() on child for children that are partially inside
    if child.x >= x and child.x + child.w <= x + w
      and child.y >= y and child.y + child.h <= y + h
    then
      tty.pushwin { x=child.x-x, y=child.y-y, w=child.w, h=child.h }
      child:renderAll()
      tty.popwin()
    end
  end
end

function VList:clear()
  self._children = {}
end

return VList
