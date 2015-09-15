local MainWin = ui.Window:subclass {
  name = "main";
  visible = true;
}

function MainWin:render()
  local player = game.get('player')
  local x,y,z = player:position()
  game.getMap(z):render_screen(x,y)
end

function MainWin:key_any(key, cmd)
  return ui.Window.handleEvent(game.get('player'), key, cmd)
end

return MainWin
