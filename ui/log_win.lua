local LogWin = ui.Window:subclass {
  name = "log";
  visible = true;
}

function LogWin:__init(...)
  ui.Window.__init(self, ...)
  self.list = ui.List {
    visible = true;
    name = "loglist";
    x = 1; y = 1;
    w = self.w-2;
    h = self.h-2;
    position = "fixed";
  }
  self:attach(self.list)
  self.list.w = self.w-2
  self.list.h = self.h-2
end

function LogWin:render()
  ui.box(nil, 'Log')
  local list_i = 1
  for i,line in ipairs(game.getLog()) do
    for _,subline in ipairs(line:wrap(self.list.w)) do
      self.list[list_i] = { text=subline }
      list_i = list_i + 1
      self.list:scroll_to_index(#self.list)
    end
  end
end

return LogWin
