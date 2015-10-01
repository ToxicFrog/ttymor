local LogWin = ui.Box:subclass {
  name = "log";
  visible = true;
  colour = { 192, 192, 192 };
}

function LogWin:__init(...)
  ui.Window.__init(self, ...)
  self.content = ui.List {
    visible = true;
    name = "loglist";
    x = 1; y = 1;
    position = "fixed";
    w = self.w-2;
    h = self.h-2;
  }
end

function LogWin:resize(w, h)
  self.w = w
  self.h = h
  return w-2,h-2
end

function LogWin:render()
  if game.log.dirty then
    self.content:clear()
    for turn in game.log:turns() do
      for _,line in ipairs(turn) do
        for _,subline in ipairs(line:wrap(self.content.w)) do
          self.content:add(subline)
        end
      end
    end
    for _,line in ipairs(game.log:currentTurn()) do
      for _,subline in ipairs(line:wrap(self.content.w)) do
        self.content:add {
          text = subline; colour = { 255, 255, 255 };
        }
      end
    end
    game.log.dirty = false
    self.content:scroll_to_index(-1)
  end
  ui.Box.render(self)
end

function LogWin:cmd_scrollup()
  self.content:page_up()
  return true
end

function LogWin:cmd_scrolldn()
  self.content:page_down()
  return true
end

return LogWin
