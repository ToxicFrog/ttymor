--
-- Default method implementations for the tree as a whole. --
--
local Window = require 'ui.Window'

local List = Window:subclass {
  -- Number of lines scrolled down.
  scroll = 0;
  render_scrollbar = true;
}

-- scroll up/down the given number of lines, without wrapping or changing focus
function List:scroll_by(n)
  self.scroll = math.bound(self.scroll+n, 0, #self - self.h):floor()
end

-- Scroll up/down one line without wrapping or changing focus.
function List:scroll_up()
  self:scroll_by(-1)
end
function List:scroll_down()
  self:scroll_by(1)
end
-- Scroll up/down one half screen without wrapping or changing focus.
function List:page_up()
  self:scroll_by(-self.h:min(#self)/2)
end
function List:page_down()
  self:scroll_by(self.h:min(#self)/2)
end

-- Scroll so that the selected element is in the center of the screen, or close to.
function List:scroll_to_index(n)
  self.scroll = math.bound(n - self.h/2, 0, #self - self.h):floor()
end

-- Render the list. Note that this does not draw a frame around it or any such
-- decorations; if you want that wrap it in a Box.
function List:render()
  for y=0,self.h do
    local line = self[1+y+self.scroll] or { text='' }
    if line.colour then
      tty.colour(unpack(line.colour))
    end
    if line.style then
      tty.style(line.style)
    end
    tty.put(0, y, line.text)
  end
end

-- Calculate the preferred width and height of the list, based on the size of
-- its contents.
function List:resize()
  self.h = #self
  self.w = 0
  for _,line in ipairs(self) do
    self.w = self.w:max(#line.text)
  end
end

function List:__init(data)
  Window.__init(self, data)
  for i,line in ipairs(self) do
    if type(line) == 'string' then
      self[i] = { text = line }
    end
    assertf(type(line) == 'table' and line.text,
      "Bad initializer to List: element %d must be string or properly structured table, got %s",
      i, repr(line))
  end
end

return List
