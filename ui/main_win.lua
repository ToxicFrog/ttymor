local MainWin = ui.Window:subclass {
  name = "Map View";
  visible = true;
}

function MainWin:render()
  local player = game.get('player')
  local x,y,map = player:position()
  map:render_screen(x,y)
end

function MainWin:cmd_any(key, cmd)
  return ui.Window.handleEvent(game.get('player'), key, cmd)
end

function MainWin:key_any(key, cmd)
  return ui.Window.handleEvent(game.get('player'), key, cmd)
end

return MainWin
