local Window = Object:subclass {}

flags.register 'ui-perf' {
  default = false;
  help = 'Log detailed rendering performance info.';
}

function Window:renderAll()
  local t = os.clock()
  tty.pushwin(self)
  self:render()
  for _,win in ipairs(self) do
    win:renderAll()
  end
  tty.popwin()
  if flags.parsed.ui_perf and self.name then
    t = os.clock() - t
    game.log('ui-perf: %s: %3f', self.name, t)
  end
end

function Window:add(subwin)
  self:remove(subwin)
  table.insert(self, subwin)
end

function Window:remove(subwin)
  for i,v in ipairs(self) do
    if v == subwin then
      table.remove(self, i)
      return
    end
  end
end

ui.Window = Window
return Window
