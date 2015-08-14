-- Component for keyboard control of the containing entity.
local Control = {}

function Control:turn()
  local cmd = ui.readkey()
  if cmd == 'cancel' then
    ui.mainmenu()
  elseif cmd == 'up' then
    self:move(0, -1)
  elseif cmd == 'down' then
    self:move(0, 1)
  elseif cmd == 'left' then
    self:move(-1, 0)
  elseif cmd == 'right' then
    self:move(1, 0)
  elseif cmd == 'key:s-T' then
    ui.keybinds_screen()
  elseif cmd == 'key:T' then
    ui.tree_test()
  else
    game.log('Unknown command: %s', cmd)
  end
end

return Control
