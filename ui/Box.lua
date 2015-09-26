local Window = require 'ui.Window'
local Box = Window:subclass {}

function Box:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.content, 'Box %s created without content', self.name)
end

function Box:render()
  ui.box(nil, self.name)
  -- render scrollbar, if applicable
  if self.content and self.content.scrollable and self.content.max_scroll > 0 then
    local h = self.content.h
    local lines = self.content.max_scroll + h
    local sb_height = ((h/lines) * (h-2)):floor():bound(1, self.h-4)
    local sb_distance = (self.content.scroll / (lines-h) * (h - 2 - sb_height)):floor():bound(0, self.h-4-sb_height)

    ui.clear({ x=self.w-1; y=2; w=1; h=self.h-4 }, '┊')
    tty.put(self.w-1, 1, '┻')
    tty.put(self.w-1, self.h-2, '┳')
    ui.clear({ x=self.w-1; y=2+sb_distance; w=1; h=sb_height }, '▓') --█
  end

  self.content:renderAll()
end

function Box:attach(child)
  error('Box:attach')
end

function Box:detach(child)
  if child then
    error('Box:detach')
  else
    return ui.Window.detach(self)
  end
end

-- Boxes assume their configured size is authoritative; if they exceed container
-- limits the caller will assert. They trim 2 cells off each dimension for their
-- children because margins.
function Box:resize(w, h)
  return self.w-2,self.h-2
end

function Box:resizeChildren(w, h)
  self.content:resize(w, h)
end

return Box
