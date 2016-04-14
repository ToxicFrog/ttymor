--
-- Does not directly support things like subtrees or focus.
--
local Window = require 'ui.Window'

local VList = Window:subclass {
  size = { inf, 0 };
  position = { -1, -1 };
}

function VList:__init(data)
  Window.__init(self, data)
  self:clear()
  for i,line in ipairs(self) do
    self:add(line)
    self[i] = nil
  end
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
  -- Override the default child positioning loop to lay them out top to bottom
  -- rather than back to front.
  local y = 0
  for child in self:children() do
    child.y = y
    y = y + child.h
  end
end

function VList:renderSlice(x, y, w, h)
  local real_y = 0
  for child in self:children() do
    -- render child only if it is entirely inside the slice
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

-- WARNING: does not update sizing information (or scroll information for its
-- container, if applicable). Call ui.layout() after adding items.
function VList:add(child)
  if type(child) == 'string' then
    return self:add(ui.TextLine {
      content = child;
      size = {0,0};
      position = {-1,-1};
    })
  elseif child.id then
    -- assume that it's an in-game entity
    -- HACK HACK HACK, we should have an EntityListViewer or something
    return self:add(ui.EntityLine {
      content = child;
      size = {0,0};
      position = {-1,-1};
    })
  end
  self:attach(child)
end

return VList
