local HudWin = ui.Window:subclass {
  name = "HUD";
  visible = true;
}

function HudWin:render()
  ui.box(nil, 'HUD')
end

return HudWin
