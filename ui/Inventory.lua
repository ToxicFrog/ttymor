-- An inventory display. You give it an entity and optional grouping/filtering
-- functions, and it displays an inventory screen that refreshes when the
-- inventory changes.

require 'settings'

settings.Category { name = 'Inventory' }
settings.Enum {
  name = 'Sort by';
  category = 'Inventory';
  value = 'highest rank';
  values = { 'highest rank'; 'lowest rank'; 'name' };
  helps = {
    ['highest rank'] = 'Sort inventory items by highest rank first; sort items of same rank by name.',
    ['lowest rank'] = 'Sort inventory items by lowest rank first; sort items of same rank by name.',
    ['name'] = 'Sort inventory items by name only, ignoring rank.',
  };
}
local Inventory = ui.Tree:subclass {}

local sorters = {
  ['highest rank'] = function(x, y)
    if x.Item.level == y.Item.level then return x.name < y.name
    else return x.Item.level > y.Item.level
    end end;
  ['lowest rank'] = function(x, y)
    if x.Item.level == y.Item.level then return x.name < y.name
    else return x.Item.level < y.Item.level
    end end;
  ['name'] = function(x, y) return x.name < y.name end;
}

local function sortCat(cat)
  table.sort(cat, assert(sorters[settings.inventory.sort_by]))
end

local function makeOrReturnCat(cats, cat)
  if not cats[cat] then
    cats[cat] = { text = cat }
    table.insert(cats, cats[cat])
  end
  return cats[cat]
end

local function updateTreeFromInventory(self, inv)
  local items_by_category = {}
  for id,item in pairs(inv.items) do
    table.insert(makeOrReturnCat(items_by_category, self.categorize(item)), item)
  end

  -- Iterate over all children and figure out which ones are expanded
  local expanded = {}
  for child in self.content:children() do
    if child.expanded and items_by_category[child.text] then
      items_by_category[child.text].expanded = true
    end
  end
  self.content:clear()

  table.sort(items_by_category, f'x,y => x.text < y.text')
  for k,cat in ipairs(items_by_category) do
    if type(k) == 'number' then
      sortCat(cat)
      for i,item in ipairs(cat) do
        cat[i] = ui.EntityLine { entity = item }
      end
    else
      cat[k] = nil
    end
  end

  self:initFrom(items_by_category)
end

function Inventory:__init(...)
  ui.Tree.__init(self, ...)
  updateTreeFromInventory(self, self.entity.Inventory)
  self.entity.Inventory.dirty = false
end

function Inventory:cmd_update()
  if not self.entity.Inventory.dirty then return false end
  updateTreeFromInventory(self, self.entity.Inventory)
  self.entity.Inventory.dirty = false
  if not self.content:children()() then
    self:destroy()
  else
    ui.layout()
  end
  return false
end;

return Inventory
