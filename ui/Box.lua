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
  size = { 0, 0 };
  position = { 0, 0 };
}

function Box:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.content, 'Box %s created without content', self.name)
  self:attach(self.content)
end

function Box:__tostring()
  return 'Box[%s]' % self.title
end

function Box:getMargins()
  return 1,1,1,1
end

function Box:layout(w, h)
  ui.Window.layout(self, w, h)
  self.max_scroll = self.content.h - (self.h - 2)
  self:scroll_by(0)
end

function Box:getChildSize(w, h)
  local ch_w,ch_h = ui.Window.getChildSize(self, w, h)
  -- We lie about our child size because if it's larger than we are, we only
  -- display a slice of it and enable scrolling.
  return ch_w,ch_h:min(h)
end

function Box:render()
  ui.box(nil, self.title or self.name, self.faces)
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
    ui.clear({ x=self.w-1; y=2; w=1; h=self.h-4 }, '┊')
    tty.put(self.w-1, 1, '┻')
    tty.put(self.w-1, self.h-2, '┳')
    -- draw scrollbar
    ui.clear({ x=self.w-1; y=2+sb_offset; w=1; h=sb_height }, '▓') --█
  end
end

function Box:renderChildren()
  if self.max_scroll > 0 then
    for child in self:children() do
      tty.pushwin { x=1; y=1; w=self.w-2; h=self.h-2; }
      child:renderSlice(0, self.scroll, self.w, self.h-2)
      tty.popwin()
    end
  else
    ui.Window.renderChildren(self)
  end
end

-- scroll up/down the given number of lines, without wrapping or changing focus
function Box:scroll_by(n)
  self.scroll = math.bound(self.scroll+n, 0, self.max_scroll):floor()
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
end


return Box
