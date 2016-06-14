local Window = require 'ui.Window'
local Box = Window:subclass {
  -- how far down are we scrolled?
  scroll = 0;
  -- how far down *can* we scroll?
  max_scroll = 0;
  -- do we display a scrollbar and let the user scroll us?
  -- note that even if this is false, the :scrollTo API is still available --
  -- we just won't render the scrollbar.
  -- It's also automatically hidden if max_scroll <= 0.
  display_scrollbar = true;
  position = { 0.5, 0.5 };
  margins = { up=1, dn=1, lf=1, rt=1 };
}

function Box:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.content, 'Box %s created without content', self.name)
  self:attach(self.content)
end

function Box:__tostring()
  return 'Box[%s]' % (self.title or self.name)
end

function Box:layoutExpand(...)
  ui.Window.layoutExpand(self, ...)
  self.max_scroll = self.content.h - (self.h - 2)
  self.content_y = self.content.y
  self:scroll_by(0)
end

function Box:maxSize(bb)
  assert(self.w <= bb.w, 'Box too wide for container')
  self.h = self.h:min(bb.h)
  return Window.maxSize(self, bb)
end

function Box:render()
  ui.box({x=0,y=0,w=self.w,h=self.h}, self.title, self.faces)
  -- render scrollbar, if applicable
  if self.display_scrollbar and self.max_scroll > 0 then
    -- if we're half as tall as our content, the scrollbar takes up half the
    -- gutter
    local gutter_height = self.h - 4
    local content_lines = self.content.h
    local sb_height = (self.h/self.content.h * gutter_height):floor():max(1)

    -- SB offset ranges from 0 (scroll=0) to max_offset (scroll=max_scroll)
    local sb_max_offset = gutter_height - sb_height
    local sb_offset = (self.scroll/self.max_scroll * sb_max_offset):floor()

    -- draw gutter
    ui.fill({ x=self.w-1; y=2; w=1; h=self.h-4 }, '┊')
    tty.put(self.w-1, 1, '┻')
    tty.put(self.w-1, self.h-2, '┳')
    -- draw scrollbar
    ui.fill({ x=self.w-1; y=2+sb_offset; w=1; h=sb_height }, '▓') --█
  end
end

-- scroll up/down the given number of lines, without wrapping or changing focus
function Box:scroll_by(n)
  self.scroll = math.bound(self.scroll+n, 0, self.max_scroll):floor()
  self.content.y = self.content_y - self.scroll
end

-- Scroll up/down one line without wrapping or changing focus.
function Box:scroll_up()
  self:scroll_by(-1)
end
function Box:scroll_down()
  self:scroll_by(1)
end
-- Scroll up/down one half screen without wrapping or changing focus.
function Box:page_up()
  self:scroll_by(-self.h:min(self.content.h)/2)
end
function Box:page_down()
  self:scroll_by(self.h:min(self.content.h)/2)
end

-- Scroll so that the selected element is in the center of the screen, or close to.
function Box:scroll_to_line(n)
  if n < 0 then
    n = n % self.content.h
  end
  self.scroll = math.bound(n - self.h/2, 0, self.max_scroll):floor()
  return self:scroll_by(0)
end


return Box
