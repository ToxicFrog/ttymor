-- Component for keyboard control of the containing entity.
-- FIXME: right now the concept of keyboard control vs. turn execution is all
-- kind of tangled up in this component. It should be separated more cleanly.
-- Somehow.
local Control = {}
local verb_info = require 'ui.verbs'

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

function Control:verb(verb, object)
  self:message('verb_'..verb, object)
  object:message('verb_'..verb..'_by', self)
end

local function makeCellTree(filter, x, y, map)
  local tree = ui.CellTree {
    title = 'Surroundings';
    cells = {{x,y},{x+1,y},{x-1,y},{x,y+1},{x,y-1}};
    map = map;
    filter = filter;
  }

  -- if the tree is nonempty, attach it
    tree.visible = true
    ui.main_win:attach(tree)
    ui.main_win:layout()
  -- FIXME
end

-- When we get an "activate" command, we need to build a menu of reachable objects
-- that can be interacted with (i.e. have a nonempty response to the <verbs> message).
function Control:cmd_activate()
  local function filter(ent)
    local verbs = {}; ent:message('verbs', verbs)
    return next(verbs)
  end

  makeCellTree(filter, self:position())
  return true
end

function Control:cmd_any(_, cmd)
  local verb = cmd:match('verb_(.*)')
  if not verb then return false end

  local function filter(ent)
    local verbs = {}; ent:message('verbs', verbs)
    return verbs[verb]
  end

  makeCellTree(filter, self:position())
  return true
end

function Control:cmd_inventory()
  game.log("-- inventory --")
  self:listInventory()
  game.log("-- end --")
  return true
end

function Control:cmd_exit_game()
  love.event.quit()
end

function Control:cmd_update_hud()
  local x,y,map = self:position()
  local cell = map:cell(x, y)
  local list = {}
  for i=1,#cell do
    local entity = cell[#cell-i+1]
    if entity.name ~= 'floor' and entity.name ~= 'player' then
      table.insert(list, ui.EntityLine { entity = entity })
    end
  end
  ui.log_win.title = cell.name
  if #list > 0 then
    ui.setHUD(cell.name, list)
    return true
  else
    return false
  end
end

return Control
