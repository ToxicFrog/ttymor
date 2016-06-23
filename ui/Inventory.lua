-- An inventory display. You give it an entity and optional grouping/filtering
-- functions, and it displays an inventory screen that refreshes when the
-- inventory changes.

require 'settings'

settings.Category { name = 'Inventory' }

for _,category in ipairs { 'Weapons', 'Armour', 'Consumables', 'Crafting', 'Ammo' } do
  settings.Enum {
    name = 'Sort %s By' % category;
    category = 'Inventory';
    value = 'highest rank';
    values = { 'highest rank', 'lowest rank', 'name' };
    helps = {
      ['highest rank'] = 'Sort inventory items by highest rank first; sort items of same rank by name.',
      ['lowest rank'] = 'Sort inventory items by lowest rank first; sort items of same rank by name.',
      ['name'] = 'Sort inventory items by name only, ignoring rank.',
    };
  }
  settings.Enum {
    name = 'Group %s By' % category;
    category = 'Inventory';
    value = 'category and subcategory';
    values = { 'category and subcategory', 'category only', 'subcategory only' };
    helps = {
      ['category and subcategory'] = 'Group items into subcategories, and all subcategories under one top-level category.';
      ['category only'] = 'Group all items into a single top-level category';
      ['subcategory only'] = 'Group items into subcategories at the top level.';
    }
  }
end

local Inventory = ui.Tree:subclass {}

local function sortCat(cat, compare)
  if cat._contains_items then
    table.sort(cat, compare)
    for i,v in ipairs(cat) do
      cat[i] = ui.EntityLine { entity = v }
    end
  else
    table.sort(cat, f'x,y => x.text < y.text')
    for i,subcat in ipairs(cat) do
      sortCat(subcat, compare)
    end
  end
end

local function makeOrReturnCat(cats, cat)
  if not cats[cat] then
    cats[cat] = { text = cat }
    table.insert(cats, cats[cat])
  end
  return cats[cat]
end

local function insertItem(cats, item, cat, ...)
  log.debug('insertItem: %s %s %s %d',
    cats.text, item, cat, select('#', ...))
  if not cat then
    cats._contains_items = true
    return table.insert(cats, item)
  end

  return insertItem(makeOrReturnCat(cats, cat), item, ...)
end

local function updateTreeFromInventory(self, inv)
  local items_by_category = {}
  for id,item in pairs(inv.items) do
    insertItem(items_by_category, item, self.categorize(item))
  end

  -- Iterate over all children and figure out which ones are expanded
  local expanded = {}
  for child in self.content:children() do
    if child.expanded and items_by_category[child.text] then
      items_by_category[child.text].expanded = true
    end
  end
  self.content:clear()

  sortCat(items_by_category, self.compare)

  self:initFrom(items_by_category)
end

local function default_categorize(item)
  local category,subcategory = item.Item.category, item.Item.subcategory
  local group_by = settings.inventory['group_%s_by' % category:lower()]
  if group_by == 'category only' then
    return category
  elseif group_by == 'subcategory only' then
    return subcategory
  elseif group_by == 'category and subcategory' then
    return category,subcategory
  else
    log.fatal("Invalid value %s for configuration key settings.inventory.group_%s_by",
      group_by, category:lower())
  end
end

local function default_compare(x, y)
  assert(x.Item.category == y.Item.category)
  local sort_by = settings.inventory['sort_%s_by' % x.Item.category:lower()]
  if sort_by == 'name' or x.Item.level == y.Item.level then
    return x.name < y.name
  elseif sort_by == 'highest rank' then
    return x.Item.level > y.Item.level
  elseif sort_by == 'lowest rank' then
    return x.Item.level < y.Item.level
  else
    log.fatal("Invalid value %s for configuration key settings.inventory.sort_%s_by",
      sort_by, x.Item.category:lower())
  end
end

function Inventory:__init(...)
  self.categorize = default_categorize
  self.compare = default_compare
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
end

return Inventory
