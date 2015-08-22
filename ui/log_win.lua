local LogWin = ui.Window:subclass {
  name = "log";
}

function LogWin:render()
  ui.box(nil, 'Log')
  local h = self.h
  local log = game.getLog()
  for y=h-2,1,-1 do
    local line = (log[#log-h+y+1] or ""):sub(1, self.w-2)
    tty.put(1, y, line)
  end
end

return LogWin
