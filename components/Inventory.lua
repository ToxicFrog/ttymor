local Inventory = {}

function Inventory:msg_init()
  self.Inventory.stacks = {}
  self.Inventory.items = {}
end

function Inventory:msg_verb_pickup(ent)
  self:getItem(ent)
end

function Inventory:msg_verb_drop(ent)
  self:dropItem(ent)
end

function Inventory:msg_verb_dropN(ent)
  game.log("dropN: not implemented yet")
end

function Inventory:cmd_inventory(ent)
  ui.tree {
    title = 'Inventory';
    cmd_update = function(tree)
      tree.content:clear()
      for k,v in pairs(self.Inventory.items) do
        tree.content:attach(ui.EntityLine { entity = v })
      end
      if not tree.content:children()() then
        tree:destroy()
      else
        ui.layout()
      end
      return false
    end;
  }
  return true
end

function Inventory:getItem(item)
  game.log("You pick up %s", item)
  local stacks,items = self.Inventory.stacks,self.Inventory.items
  self:claim(item:release())
  item.Item.held_by = self

  items[item.id] = item
  if item.Item.stackable then
    if stacks[item.type] then
      -- We delete the item currently in the inventory because the item we just
      -- picked up is about to get a pickup_by message, and if we delete *that*
      -- we're in for a rough time.
      local old_stack = stacks[item.type]:release()
      item:stackWith(old_stack)
    else
    end
    stacks[item.type] = item
  end
end

function Inventory:msg_release(item)
  local stacks,items = self.Inventory.stacks,self.Inventory.items
  if item.Item.stackable and stacks[item.type] and stacks[item.type].id == item.id then
    stacks[item.type] = nil
  end
  items[item.id] = nil
  item.Item.held_by = nil
end

function Inventory:dropItem(item)
  game.log("You drop %s", item)
  local x,y,map = self:position()
  -- Map takes ownership of item. Our msg_release handler will be
  -- called to clear the inventory structures.
  map:placeAt(x, y, item)
  map:placeAt(x, y, self) -- bring self to top
end

return Inventory
