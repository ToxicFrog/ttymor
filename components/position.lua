local position = {}

function position:map()
  return game.getMap(self._map)
end

function position:move(ent, dx, dy)
  local x,y = self.x,self.y
  if self:map():try_move(x+dx, y+dy) then
    ent:moveTo(x + dx, y + dy)
  end
end

function position:setMap(ent, map)
  if self._map then
    self:map():removeFrom(ent, self.x, self.y)
  end
  if type(map) == 'number' then
    self._map = map
  else
    self._map = map.depth
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
  return self.x,self.y,self._map
end

return position
