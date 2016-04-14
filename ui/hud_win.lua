local HudWin = ui.Box:subclass {
  name = 'hud';
  visible = true;
  stack = nil;
  top = nil;
  colour = { 192, 192, 192 };
  display_scrollbar = false;
  faces = { sw = '┣'; se = '┫'; }
}

function HudWin:__init(...)
  self.stack = {}
  self.content = ui.VList {
    visible = true;
    name = "hudlist";
  }
  ui.Box.__init(self, ...)
end

function HudWin:setContent(data)
  assert(data, "attempt to call setContent() with nil data")
  self.content:clear()
  for _,item in ipairs(data) do
    self.content:add(item)
  end
  self.top = data
  self.title = data.name
  ui.layout()
  --self:layout(self.parent.w, self.parent.h)
end

function HudWin:pushContent()
  table.insert(self.stack, self.top)
end

function HudWin:popContent()
  self:setContent(table.remove(self.stack))
end

return HudWin
