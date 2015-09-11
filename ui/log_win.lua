local LogWin = ui.Box:subclass {
  name = "log";
  visible = true;
  colour = { 192, 192, 192 };
}

function LogWin:__init(...)
  ui.Box.__init(self, ...)
  self.list = ui.List {
    visible = true;
    name = "loglist";
    x = 1; y = 1;
    position = "fixed";
  }
  self:attach(self.list)
  self.list.w = self.w-2
  self.list.h = self.h-2
end

function LogWin:render()
  if game.log.dirty then
    self.list:clear()
    for turn in game.log:turns() do
      for _,line in ipairs(turn) do
        for _,subline in ipairs(line:wrap(self.list.w)) do
          self.list:add(subline)
        end
      end
    end
    for _,line in ipairs(game.log:currentTurn()) do
      for _,subline in ipairs(line:wrap(self.list.w)) do
        self.list:add {
          text = subline; colour = { 255, 255, 255 };
        }
      end
    end
    -- HACK HACK HACK
    -- Oh my god, this is awful.
    -- Maybe we can do something about it after the input handling rewrite.
    ui.log_win.list:scroll_to_index(-1)
    game.log.dirty = false
    self.list:scroll_to_index(-1)
  end
  ui.Box.render(self)
end

return LogWin
