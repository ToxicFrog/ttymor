local Window = require 'ui.Window'
local Box = Window:subclass {}

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
end

function Box:attach(child)
  assertf(#self.children == 0, 'Boxes can only have one child.')
  Window.attach(self, child)
  self.content = child
end

function Box:detach(child)
  Window.detach(self, child)
  if child then
    self.content = nil
  end
end

return Box
