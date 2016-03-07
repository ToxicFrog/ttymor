local Item = {
  stackable = true;
}

-- TODO: dropItem/getItem not actually implemented yet!
function Item:__frob(frobber)
function Item:__frob(frobber, actions)
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
        --return frobber:getItem(self)
      end;
    })
  end
end

return Item
