local Inventory = {}

function Inventory:__init()
  self.Inventory.stacks = self.Inventory.stacks or {}
  self.Inventory.uniques = self.Inventory.uniques or {}
end

function Inventory:getItem(item)
  game.log("You pick up %s", item)
  local stacks,uniques = self.Inventory.stacks,self.Inventory.uniques
  self:claim(item:release())
  if item.Item.stackable then
    if stacks[item.type] then
      -- deletes item
      stacks[item.type]:stackWith(item)
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
