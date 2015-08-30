local Position = {}

function Position:map()
  return game.getMap(self.Position.z)
end

function Position:move(dx, dy)
  local x,y = self.Position.x,self.Position.y
  local blocker = self:map():blocked(x+dx, y+dy, 'walk')
  if blocker then
    return blocker:touchedBy(self)
  else
    self:moveTo(x + dx, y + dy)
    local cell = self:map():cell(x+dx, y+dy)
    local list = {}
    for i=1,#cell do
      list[i] = cell[#cell-i+1]
    end
    -- HACK HACK HACK
    -- This means that every enemy that moves will override the HUD with the
    -- contents of its square. TODO: move this somewhere player-specific.
    ui.setHUD(nil, list)
  end
end

function Position:setMap(z)
  if self.Position.z then
    self:map():removeFrom(self, self.Position.x, self.Position.y)
  end
  if type(z) == 'number' then
    self.Position.z = z
  else
    self.Position.z = z.depth
  end
end

function Position:moveTo(x, y)
  if self.Position.x and self.Position.y then
    self:map():removeFrom(self, self.Position.x, self.Position.y)
  end
  self:map():placeAt(self, x, y)
  self.Position.x,self.Position.y = x,y
end

function Position:position()
  return self.Position.x,self.Position.y,self.Position.z
end

return Position
