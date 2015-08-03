local position = {}

function position:map()
  return game.getMap(self.z)
end

function position:move(ent, dx, dy)
  local x,y = self.x,self.y
  if self:map():try_move(x+dx, y+dy) then
    ent:moveTo(x + dx, y + dy)
  end
end

function position:setMap(ent, z)
  if self.z then
    self:map():removeFrom(ent, self.x, self.y)
  end
  if type(z) == 'number' then
    self.z = z
  else
    self.z = z.depth
  end
end

function position:moveTo(ent, x, y)
  if self.x and self.y then
    self:map():removeFrom(ent, self.x, self.y)
  end
  self:map():placeAt(ent, x, y)
  self.x,self.y = x,y
end

function position:position(ent)
  return self.x,self.y,self.z
end

return position
