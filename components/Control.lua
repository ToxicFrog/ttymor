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

function Control:interactWith(ent)
  local tree = { name = ent.name }
  local verbs = {}; ent:message('verbs', verbs)
  for verb in pairs(verbs) do
    assert(verb_info[verb], verb)
    table.insert(tree, {
      name = verb_info[verb].name;
      help = verb_info[verb].help;
      activate = function(node)
        node.tree:cancel()
        self:verb(verb, ent)
      end;
    })
  end
  ui.tree(tree)
end

-- When we get an "activate" command, we need to build a menu of reachable objects
-- that can be interacted with (i.e. have a nonempty response to the <verbs> message).
function Control:cmd_activate()
  -- frob surrounding objects
  local x,y,map = self:position()

  local tree = { name = "Surroundings" }
  for _,cell in ipairs {{x,y,"⌖"}, {x,y-1,"⤊"}, {x,y+1,"⤋"}, {x-1,y,"⇚"}, {x+1,y,"⇛"}} do
    for ent in map:contents(cell[1], cell[2]) do
      local verbs = {}; ent:message("verbs", verbs)
      if next(verbs) then
        table.insert(tree, {
          name = cell[3]..' '..ent.name;
          activate = function(node)
            node.tree:cancel()
            self:interactWith(ent)
          end;
        })
      end
    end
  end
  if #tree > 0 then
    ui.tree(tree)
  end
  return true
end

function Control:cmd_inventory()
  game.log("-- inventory --")
  self:listInventory()
  game.log("-- end --")
  return true
end

function Control:cmd_pickup()
  game.log("pickup: not implemented yet")
  return true
end

return Control
