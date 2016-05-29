local Item = {
  stackable = true;
  count = 1;
  description = "***BUG***";
  level = 0;
  category = 'Misc';
}

-- TODO: figure out how to let different components add things to the examination
-- results, e.g. equipment should show stats and comparison to current gear, food
-- should show amount healed, etc.
local x_order = { 'Item' }
function Item:msg_verb_examine_by()
  local desc = {}
  self:message('describe', desc)
  local desc_lines = {}
  for _,name in ipairs(x_order) do
    for _,line in ipairs(desc[name] or {}) do
      table.insert(desc_lines, line)
    end
  end
  ui.message(tostring(self), desc_lines)
end

function Item:msg_describe(desc)
  local stars
  if self.Item.level <= 5 then
    stars = ('★'):rep(self.Item.level)
  else
    stars = ('❂'):rep(self.Item.level-5)..('★'):rep(5-self.Item.level)
  end

  desc.Item = { '%-5s    Ƶ%s' % { stars, self.Item.price } }
  if self.Item.special then
    table.insert(desc.Item, '[non-spawning]')
  end
  table.insert(desc.Item, '')
  table.insert(desc.Item, self.Item.description)

  return desc
end

function Item:stackWith(other)
  assert(other.type == self.type)
  assert(self.Item.stackable and other.Item.stackable)

  self.Item.count = self.Item.count + other.Item.count
  other:delete()
end

function Item:msg_verbs(verbs)
  verbs.examine = true
  if self.Item.held_by then
    verbs.drop = true
    verbs.dropN = true
  else
    verbs.pickup = true
  end
  return verbs
end

function Item:msg_tostring(string)
  if self.Item.count > 1 then
    table.insert(string, 'x%d' % self.Item.count)
  end
end

return Item
