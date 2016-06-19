-- An inventory display. You give it an entity and optional grouping/filtering
-- functions, and it displays an inventory screen that refreshes when the
-- inventory changes.

local Inventory = ui.Tree:subclass {}

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
      table.sort(cat, f'x,y => x.name < y.name')
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
