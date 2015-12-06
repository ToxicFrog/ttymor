local HudWin = ui.Box:subclass {
  name = 'hud';
  position = 'fixed';
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
  self.h = #data+2
  self.content.h = #data
  ui.log_win.y = self.h - 1
  ui.log_win:reposition(self.w, ui.screen.h - self.h + 1)
  ui.log_win.content:scroll_to_index(-1)
end

function HudWin:pushContent()
  table.insert(self.stack, self.top)
end

function HudWin:popContent()
  self:setContent(table.remove(self.stack))
end

return HudWin
