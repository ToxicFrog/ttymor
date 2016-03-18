local Item = {
  stackable = true;
  count = 1;
  description = "***BUG***"
}

-- TODO: figure out how to let different components add things to the examination
-- results, e.g. equipment should show stats and comparison to current gear, food
-- should show amount healed, etc.
function Item:msg_verb_examine_by()
  local desc = {}
  table.insert(desc, self.Item.description)
  table.insert(desc, '')
  table.insert(desc, '  Components:')
  for cat in pairs(self.Item.categories) do
    table.insert(desc, cat)
  end
  ui.message(self.name, desc)
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

return Item
