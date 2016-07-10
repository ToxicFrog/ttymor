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

-- a Tree has a .content field which is a VList which contains the top level
-- some of the children will be Expanders, which will have a .content field,
-- which is a VList etc
-- We do something ugly here: reach directly into the _children array of our
-- child elements to sort them.
local function sortTree(root, cmp)
  table.sort(root.content._children, cmp)
  for _,expander in pairs(root._children_by_name) do
    sortTree(expander, cmp)
    -- Display expanders or not based on whether they have any contents.
    expander.visible = toboolean(expander.content:children()())
  end
end

function Inventory:addItem(item, expander, cat, ...)
  if not cat then
    expander.content:attach(ui.EntityLine { entity = item })
  else
    if not expander._children_by_name[cat] then
      -- Make sure intermediate expanders exist.
      local child = ui.Expander {
        text = cat;
        content = ui.VList {};
        _children_by_name = {};
      }
      expander._children_by_name[cat] = child
      expander.content:attach(child)
    end
    return self:addItem(item, expander._children_by_name[cat], ...)
  end
end

local function clearExpanders(root)
  root.content:clear()
  for _,child in pairs(root._children_by_name) do
    clearExpanders(child)
    root.content:attach(child)
  end
end

function Inventory:updateTreeFromInventory()
  clearExpanders(self)

  for id,item in pairs(self.entity.Inventory.items) do
    if self.filter(item) then
      self:addItem(item, self, self.categorize(item))
    end
  end

  local function cmp(x, y)
    -- Categories sort before everything else.
    if x._header and not y._header then return true end
    if y._header and not x._header then return false end
    -- Categories are sorted relative to each other by title.
    if x._header and y._header then return x.text < y.text end
    -- Everything else uses the item-level comparator.
    return self.compare(x.entity, y.entity)
  end

  sortTree(self, cmp)
end

-- Default categorization function. Takes an item, returns zero or more categories
-- for it from least to most specific (e.g. "Consumable","Potion"). Items for
-- which it returns nothing will appear at the top level; other items will appear
-- in the menu heirarchy according to the values returned.
-- The default implementation respects the group_foo_by settings and returns either
-- the item category, subcategory, or both.
function Inventory.categorize(item)
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

-- Default item ordering function. Takes two items, returns true if the first
-- should sort before the second.
-- The default implementation respects the sort_foo_by settings and orders based
-- on name and optionally rank.
function Inventory.compare(x, y)
  local sort_by = settings.inventory['sort_%s_by' % x.Item.category:lower()]
  if sort_by == 'name' or x.Item.rank == y.Item.rank then
    return x.name < y.name
  elseif sort_by == 'highest rank' then
    return x.Item.rank > y.Item.rank
  elseif sort_by == 'lowest rank' then
    return x.Item.rank < y.Item.rank
  else
    log.fatal("Invalid value %s for configuration key settings.inventory.sort_%s_by",
      sort_by, x.Item.category:lower())
  end
end

-- Default item filter function. Instantiations can use this to control which
-- items are displayed at all, e.g. the ammo selection screen showing only ammo.
function Inventory.filter(item)
  return true
end

function Inventory:__init(...)
  ui.Tree.__init(self, ...)
  self._children_by_name = {}
  self:updateTreeFromInventory()
  self.entity.Inventory.dirty = false
end

function Inventory:cmd_update()
  if not self.entity.Inventory.dirty then return false end
  self:updateTreeFromInventory()
  self.entity.Inventory.dirty = false
  if not self.content:children()() then
    self:destroy()
  else
    ui.layout()
  end
  return false
end

return Inventory
