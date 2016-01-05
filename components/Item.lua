local Item = {
  stackable = true;
}

-- TODO: dropItem/getItem not actually implemented yet!
function Item:__frob(frobber)
  if self.Item.held_by then
    return {
      name = "Drop";
      activate = function()
        game.log('Drop '..tostring(self))
        return true
        --return self.Item.held_by:dropItem(self)
      end;
    }
  else
    return {
      name = "Pick Up";
      activate = function()
        game.log('Pickup '..tostring(self))
        return true
        --return frobber:getItem(self)
      end;
    }
  end
end

return Item
