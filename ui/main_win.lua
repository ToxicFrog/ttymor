local MainWin = ui.Window:subclass {
  name = "main";
}

function MainWin:render()
  local player = game.get('player')
  local x,y,z = player:position()
  game.getMap(z):render_screen(x,y)
end

return MainWin
