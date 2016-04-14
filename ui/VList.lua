--
-- A vertical list of items. Can be scrolled.
-- Does not directly support things like subtrees or focus.
--
local Window = require 'ui.Window'

local VList = Window:subclass {
  -- Number of lines scrolled down.
  scroll = 0;
  max_scroll = 0;
  scrollable = true;
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

function VList:getChildSize(max_w, max_h)
  w = 0
  h = 0
  for child in self:children() do
    w = w:max(child.w)
    h = h + child.h
  end
  log.debug("VList:getChildSize: %dx%d", w:min(max_w), h:min(max_h))
  return w:min(max_w),h:min(max_h)
end

function VList:layout(w, h)
  Window.layout(self, w, h)
  -- Override the default child positioning loop to lay them out top to bottom
  -- rather than back to front.
  local y = 0
  for child in self:children() do
    child.y = y
    y = y + child.h
    log.debug("Reposition: %s: %d,%d", child.name, child.x, child.y)
  end
  self.max_scroll = (#self._children - self.h):max(0)
  -- This makes sure that our scrolling amount is in bounds and visibility is
  -- updated for the new scroll amount
  self:scroll_by(0)
end

-- ERROR: this doesn't update the positions of the children, so we figure out
-- what window needs to be rendered correctly, but then render it in the original
-- (un-scrolled) place.
function VList:updateVisibility()
  log.debug("VList:vis: scroll=%d", self.scroll)
  for child in self:children() do
    child.visible = child.y >= self.scroll
      and child.y + child.h <= self.scroll + self.h
  end
end

function VList:clear()
  self._children = {}
  self.scroll,self.max_scroll = 0,0
end

-- WARNING: does not update max_scroll. You need to call ui.layout() to update
-- that information after :adding.
function VList:add(child)
  if type(child) == 'string' then
    return self:add(ui.TextLine {
      content = child;
      name = "VList$TextLine["..child.."]";
      size = {0,0};
      position = {-1,-1};
    })
  elseif child.id then
    -- assume that it's an in-game entity
    -- HACK HACK HACK, we should have an EntityListViewer or something
    return self:add(ui.TextLine {
      content = child.name;
      name = "VList$EntityLine["..child.id.."]";
      size = {0,0};
      position = {-1,-1};
    })
  end
  self:attach(child)
end

-- scroll up/down the given number of lines, without wrapping or changing focus
function VList:scroll_by(n)
  self.scroll = math.bound(self.scroll+n, 0, self.max_scroll):floor()
  self:updateVisibility()
end

-- Scroll up/down one line without wrapping or changing focus.
function VList:scroll_up()
  self:scroll_by(-1)
end
function VList:scroll_down()
  self:scroll_by(1)
end
-- Scroll up/down one half screen without wrapping or changing focus.
function VList:page_up()
  self:scroll_by(-self.h:min(#self._children)/2)
end
function VList:page_down()
  self:scroll_by(self.h:min(#self._children)/2)
end

-- Scroll so that the selected element is in the center of the screen, or close to.
function VList:scroll_to_index(n)
  if n < 0 then
    n = #self._children - n
  end
  self.scroll = math.bound(n - self.h/2, 0, self.max_scroll):floor()
  self:updateVisibility()
end

return VList
