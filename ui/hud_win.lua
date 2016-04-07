local HudWin = ui.Box:subclass {
  name = 'hud';
  visible = true;
  stack = nil;
  top = nil;
  colour = { 192, 192, 192 };
  scrollable = false;
  faces = { sw = '┣'; se = '┫'; }
}

function HudWin:__init(...)
  ui.Window.__init(self, ...)
  self.stack = {}
  self.content = ui.List {
    visible = true;
    name = "hudlist";
  }
  self:attach(self.content)
end

function HudWin:setContent(data)
  assert(data, "attempt to call setContent() with nil data")
  self.content.content = data
  self.top = data
  self.name = data.name
  self:layout(self.w, self.h)
end

function HudWin:pushContent()
  table.insert(self.stack, self.top)
end

function HudWin:popContent()
  self:setContent(table.remove(self.stack))
end

return HudWin
