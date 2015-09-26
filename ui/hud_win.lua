local HudWin = ui.Box:subclass {
  position = 'fixed';
  visible = true;
  stack = nil;
  top = nil;
  colour = { 192, 192, 192 };
  scrollable = false;
}

function HudWin:__init(...)
  ui.Window.__init(self, ...)
  self.stack = {}
  self.content = ui.List {
    visible = true;
    name = "hudlist";
    x = 1; y = 1;
    position = "fixed";
    w = self.w-2;
    h = self.h-2;
  }
end

function HudWin:setContent(data)
  self.content.content = data
  self.top = data
  self.name = data.name
end

function HudWin:pushContent()
  table.insert(self.stack, self.top)
end

function HudWin:popContent()
  self:setContent(table.remove(self.stack))
end

return HudWin
