local Position = {}

function Position:move(dx, dy)
  local x,y = self.Position.x,self.Position.y
  local blocker = self.Position.map:blocked(x+dx, y+dy, 'walk')
  if blocker then
    if blocker.touchedBy then
      return blocker:touchedBy(self)
    else
      return nil
    end
  else
    self:moveTo(x + dx, y + dy)
  end
end

function Position:setMap(map)
  if self.Position.map then
    self.Position.map:removeFrom(self, self.Position.x, self.Position.y)
  end
  self.Position.map = map
end

function Position:moveTo(x, y)
  if self.Position.x and self.Position.y then
    self.Position.map:removeFrom(self, self.Position.x, self.Position.y)
  end
  self.Position.map:placeAt(self, x, y)
  self.Position.x,self.Position.y = x,y
  -- HACK HACK HACK
  -- This should be moved into a Player-specific component.
  if self.type == 'Player' then
    local cell = self.Position.map:cell(x, y)
    local list = {}
    for i=1,#cell do
      list[i] = cell[#cell-i+1]
    end
    ui.setHUD(cell.name, list)
  end
end

function Position:position()
  return self.Position.x,self.Position.y,self.Position.map
end

return Position
