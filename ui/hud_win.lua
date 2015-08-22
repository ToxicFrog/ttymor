local HudWin = ui.Window:subclass {
  name = "HUD";
}

function HudWin:render()
  ui.box(nil, 'HUD')
end

return HudWin
