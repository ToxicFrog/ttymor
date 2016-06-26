local LogWin = ui.Box:subclass {
  name = "log";
  visible = true;
  colour = { 192, 192, 192 };
}

function LogWin:__init(...)
  self.content = ui.VList {
    visible = true;
    name = "loglist";
    position = { 0, 1 };
    size = { inf, 0 };
  }
  ui.Box.__init(self, ...)
end

function LogWin:render()
  if game.log.dirty then
    local ww = self:getChildBB().w
    self.content:clear()
    for turn in game.log:turns() do
      for _,line in ipairs(turn) do
        self.content:attach(ui.WrappingTextLine { text = line; wrap_width = ww })
      end
    end
    for _,line in ipairs(game.log:currentTurn()) do
      self.content:attach(ui.WrappingTextLine { text = line; wrap_width = ww })
    end
    game.log.dirty = false
    self:layout()
    self:scroll_to_line(-1)
  end
  ui.Box.render(self)
end

function LogWin:cmd_scrollup()
  self:page_up()
  return true
end

function LogWin:cmd_scrolldown()
  self:page_down()
  return true
end

return LogWin
