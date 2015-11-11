--
-- Default method implementations for the tree as a whole. --
--
local Window = require 'ui.Window'

local List = Window:subclass {
  -- Number of lines scrolled down.
  h = 1;
  scroll = 0;
  max_scroll = 0;
  scrollable = true;
}

-- scroll up/down the given number of lines, without wrapping or changing focus
function List:scroll_by(n)
  self.scroll = math.bound(self.scroll+n, 0, self.max_scroll):floor()
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
  self:scroll_by(-self.h:min(#self.content)/2)
end
function List:page_down()
  self:scroll_by(self.h:min(#self.content)/2)
end

-- Scroll so that the selected element is in the center of the screen, or close to.
function List:scroll_to_index(n)
  if n < 0 then
    n = #self.content - n
  end
  self.scroll = math.bound(n - self.h/2, 0, self.max_scroll):floor()
end

local function renderLabel(ent, x, y, w)
  if type(ent) == 'string' then
    tty.put(x, y, ent:sub(1, w))
  elseif ent.renderLabel then
    ent:renderLabel(x, y, w)
  elseif ent.text then
    if ent.colour then tty.colour(unpack(ent.colour)) end
    if ent.style then tty.style(ent.style) end
    renderLabel(ent.text, x, y, w)
  else
    error('renderLabel() called on an entity with no handler and no .text: %s', ent)
  end
end

-- Render the list. Note that this does not draw a frame around it or any such
-- decorations; if you want that wrap it in a Box.
function List:render()
  for y=0,self.h-1 do
    local line = self.content[1+y+self.scroll] or ''
    renderLabel(line, 0, y, self.w)
  end
end

-- Lists just blindly inherit the size of their parents.
function List:resize(w, h)
  self.max_scroll = (#self.content - h):max(0)
  --self.scroll = (self.scroll + self.h - h):bound(0, self.max_scroll)
  self.w = w
  self.h = h
  return w,h
end

function List:clear()
  self.content = {}
  self.scroll,self.max_scroll = 0,0
end

function List:add(line)
  if type(line) == 'string' then
    line = { text = line }
  end
  if not type(line) == 'table' and (line.text or line.renderLabel) then
    error(
      "Bad content in List: element %d must be string or properly structured table, got %s",
      #self.content+1, repr(line))
  end
  table.insert(self.content, line)
  self.max_scroll = (#self.content - self.h):max(0)
end

function List:len()
  return #self.content
end

function List:__init(data)
  Window.__init(self, data)
  self:clear()
  for i,line in ipairs(self) do
    self:add(line)
    self[i] = nil
  end
end

return List
