local HudWin = ui.Box:subclass {
  position = 'fixed';
  readonly = true;
  visible = true;
  stack = nil;
  content = nil;
  colour = { 192, 192, 192 };
  scrollable = false;
}

function HudWin:__init(...)
  ui.Box.__init(self, ...)
  self.stack = {}
  self.list = ui.List {
    visible = true;
    name = "hudlist";
    x = 1; y = 1;
    position = "fixed";
  }
  self:attach(self.list)
  self.list.w = self.w-2
  self.list.h = self.h-2
end

-- Width and height of the HUD are fixed, so this is a no-op.
function HudWin:resize() end

function HudWin:setContent(data)
  self.list.content = data
  self.content = data
  self.name = data.name
end

function HudWin:pushContent()
  table.insert(self.stack, self.content)
end

function HudWin:popContent()
  self:setContent(table.remove(self.stack))
end

return HudWin
