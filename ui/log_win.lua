local LogWin = ui.Window:subclass {
  name = "log";
  visible = true;
  colour = { 192, 192, 192 };
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
  for turn in game.log:turns() do
    for _,line in ipairs(turn) do
      for _,subline in ipairs(line:wrap(self.list.w)) do
        self.list[list_i] = { text=subline }
        list_i = list_i + 1
      end
    end
  end
  for _,line in ipairs(game.log:currentTurn()) do
    for _,subline in ipairs(line:wrap(self.list.w)) do
      self.list[list_i] = { text=subline; colour={255,255,255} }
      list_i = list_i + 1
    end
  end
  self.list:scroll_to_index(#self.list)
end

return LogWin
