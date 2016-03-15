local Inventory = {}

function Inventory:msg_init()
  self.Inventory.stacks = {}
  self.Inventory.uniques = {}
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

function Inventory:getItem(item)
  game.log("You pick up %s", item)
  local stacks,uniques = self.Inventory.stacks,self.Inventory.uniques
  self:claim(item:release())
  if item.Item.stackable then
    if stacks[item.type] then
      -- We delete the item currently in the inventory because the item we just
      -- picked up is about to get a pickup_by message, and if we delete *that*
      -- we're in for a rough time.
      item:stackWith(stacks[item.type])
      stacks[item.type] = item
    else
      stacks[item.type] = item
    end
  else
    uniques[item.id] = item
  end
end

function Inventory:dropItem(item)
  game.log("dropItem: not implemented yet")
  --local key = next(self.Inventory.stacks) or next(self.Inventory.uniques)
end

function Inventory:listInventory()
  for k,v in pairs(self.Inventory.stacks) do
    game.log("stack: %s [%d]", v, v.Item.count)
  end
  for k,v in pairs(self.Inventory.uniques) do
    game.log("unique: %s", v)
  end
end

return Inventory
