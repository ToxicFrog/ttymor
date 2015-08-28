local LogWin = ui.Window:subclass {
  name = "log";
  visible = true;
}

function LogWin:render()
  ui.box(nil, 'Log')
  local h = self.h
  local log = game.getLog()
  for i=#log,1,-1 do
    local y = self.h - 2 - #log + i
    if y < 1 then break end
    tty.put(1, y, log[i]:sub(1, self.w-2))
  end
end

return LogWin
