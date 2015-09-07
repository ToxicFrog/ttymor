-- Component for keyboard control of the containing entity.
-- FIXME: right now the concept of keyboard control vs. turn execution is all
-- kind of tangled up in this component. It should be separated more cleanly.
-- Somehow.
local Control = {}

function Control:turn()
  local cmd = ui.readkey()
  if cmd == 'cancel' then
    ui.mainmenu()
  elseif cmd == 'up' then
    game.log:nextTurn()
    self:move(0, -1)
  elseif cmd == 'down' then
    game.log:nextTurn()
    self:move(0, 1)
  elseif cmd == 'left' then
    game.log:nextTurn()
    self:move(-1, 0)
  elseif cmd == 'right' then
    game.log:nextTurn()
    self:move(1, 0)
  elseif cmd == 'scrollup' then
    -- HACK HACK HACK
    -- FIXME: during the key event handling rewrite, set up Box so that it
    -- forwards all key events to its contents, if any, and let the log handle
    -- its own scrolling.
    ui.log_win.list:page_up()
  elseif cmd == 'scrolldn' then
    ui.log_win.list:page_down()
  elseif cmd == 'activate' then
    game.log:nextTurn()
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
  else
    game.log('Unknown command: %s', cmd)
  end
end

return Control
