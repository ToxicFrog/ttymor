local Item = {
  stackable = true;
  count = 1;
  description = "***BUG***"
}

function Item:msg_verb_examine_by()
  ui.message(self.name, self.Item.description)
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
