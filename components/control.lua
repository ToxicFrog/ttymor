-- Component for keyboard control of the containing entity.
local control = {}

function control:turn(ent)
  game.log("--- turn: %s", ent)
  local cmd = ui.readkey()
  if cmd == 'cancel' then
    ui.mainmenu()
  elseif cmd == 'up' then
    ent:move(0, -1)
  elseif cmd == 'down' then
    ent:move(0, 1)
  elseif cmd == 'left' then
    ent:move(-1, 0)
  elseif cmd == 'right' then
    ent:move(1, 0)
  elseif cmd == 'key:s-T' then
    ui.keybinds_screen()
  elseif cmd == 'key:T' then
    ui.tree_test()
  else
    game.log('command: %s', cmd)
  end
end

return control
