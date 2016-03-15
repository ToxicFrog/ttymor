local Item = {
  stackable = true;
  count = 1;
}

function Item:stackWith(other)
  assert(other.type == self.type)
  assert(self.Item.stackable and other.Item.stackable)

  self.Item.count = self.Item.count + other.Item.count
  other:delete()
end

function Item:msg_verbs(verbs)
  if self.Item.held_by then
    verbs.drop = true
    verbs.dropN = true
  else
    verbs.pickup = true
  end
  return verbs
end

return Item
