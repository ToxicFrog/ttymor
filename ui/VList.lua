--
-- Does not directly support things like subtrees or focus.
--
local Window = require 'ui.Window'

local VList = Window:subclass {}

function VList:__init(data)
  Window.__init(self, data)
  self:clear()
  for i,child in ipairs(self) do
    self:attach(child)
    self[i] = nil
  end
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

function VList:clear()
  self._children = {}
end

return VList
