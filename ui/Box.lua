local Window = require 'ui.Window'
local Box = Window:subclass {}

function Box:__init(...)
  ui.Window.__init(self, ...)
  assertf(self.content, 'Box %s created without content', self.name)
end

function Box:getMargins()
  return 1,1,1,1
end

function Box:render()
  ui.box(nil, self.name, self.faces)
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

return Box
