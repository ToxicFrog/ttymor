-- Component for keyboard control of the containing entity.
-- FIXME: right now the concept of keyboard control vs. turn execution is all
-- kind of tangled up in this component. It should be separated more cleanly.
-- Somehow.
local Control = {}

function Control:cmd_cancel()
  ui.mainmenu()
  return true
end

function Control:cmd_up()
  game.log:nextTurn()
  self:move(0, -1)
  return true
end

function Control:cmd_down()
  game.log:nextTurn()
  self:move(0, 1)
  return true
end

function Control:cmd_left()
  game.log:nextTurn()
  self:move(-1, 0)
  return true
end

function Control:cmd_right()
  game.log:nextTurn()
  self:move(1, 0)
  return true
end

function Control:cmd_activate()
  game.log:nextTurn()
  -- frob surrounding objects
  local x,y,map = self:position()

  local tree = { name = "Surroundings" }
  table.insert(tree, map:frobCell(x, y, "At Feet", self) or nil)
  table.insert(tree, map:frobCell(x, y-1, "North", self) or nil)
  table.insert(tree, map:frobCell(x, y+1, "South", self) or nil)
  table.insert(tree, map:frobCell(x-1, y, "West", self) or nil)
  table.insert(tree, map:frobCell(x+1, y, "East", self) or nil)
  function tree:cmd_activate(...)
    ui.Tree.cmd_activate(self)
    self:destroy()
    return true
  end
  log.error('%s', repr(tree))
  if #tree > 0 then
    ui.tree(tree)
  end
  return true
end

function Control:cmd_inventory()
  game.log('Inventory!')
  return true
end

function Control:cmd_pickup()
  for _,item in ipairs(self.Position.map:cell(self:position())) do
    game.log('Pickup: %s', tostring(item))
  end
  return true
end

return Control
