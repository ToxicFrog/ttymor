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

function Item:msg_frob(frobber, actions)
  if self.Item.held_by then
    table.insert(actions, {
      name = "Drop";
      activate = function()
        frobber:dropItem(self)
        return true
      end;
    })
  else
    table.insert(actions, {
      name = "Pick Up";
      activate = function()
        frobber:getItem(self)
        return true
      end;
    })
  end
end

return Item
