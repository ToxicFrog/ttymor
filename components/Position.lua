local Position = {}

function Position:map()
  return game.getMap(self.Position.z)
end

function Position:move(dx, dy)
  local x,y = self.Position.x,self.Position.y
  if self:map():try_move(x+dx, y+dy) then
    self:moveTo(x + dx, y + dy)
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
