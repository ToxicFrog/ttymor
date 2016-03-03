local Position = {}

function Position:move(dx, dy)
  local x,y,map = self:position()
  local blocker = map:blocked(x+dx, y+dy, 'walk')
  if blocker then
    -- FIXME: this should be a message, not a function call
    if blocker.touchedBy then
      return blocker:touchedBy(self)
    else
      return nil
    end
  else
    self:moveTo(x + dx, y + dy)
  end
end

function Position:moveTo(x, y)
  local _,_,map = self:position()
  map:placeAt(x, y, self)
  -- HACK HACK HACK
  -- This should be moved into a Player-specific component.
  if self.type == 'Player' then
    local cell = map:cell(x, y)
    local list = {}
    for i=1,#cell do
      list[i] = cell[#cell-i+1]
    end
    ui.setHUD(cell.name, list)
  end
end

function Position:position()
  local map = self._parent
  local x,y = map:positionOf(self)
  return x,y,map
end

return Position
