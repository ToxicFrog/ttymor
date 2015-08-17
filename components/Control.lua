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
  elseif cmd == 'activate' then
    -- frob surrounding objects
    local x,y = self:position()

    local tree = { name = "Surroundings" }
    table.insert(tree, self:map():frob(x, y, "At Feet", self) or nil)
    table.insert(tree, self:map():frob(x, y-1, "North", self) or nil)
    table.insert(tree, self:map():frob(x, y+1, "South", self) or nil)
    table.insert(tree, self:map():frob(x-1, y, "West", self) or nil)
    table.insert(tree, self:map():frob(x+1, y, "East", self) or nil)
    log.error('%s', repr(tree))
    if #tree > 0 then
      ui.tree(tree)
    end
  elseif cmd == 'key:s-T' then
    ui.keybinds_screen()
  elseif cmd == 'key:T' then
    ui.tree_test()
  else
    game.log('Unknown command: %s', cmd)
  end
end

return Control
