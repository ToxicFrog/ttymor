local position = {}

function position:move(ent, dx, dy)
  if self.map:try_move(self.x + dx, self.y + dy) then
    ent:moveTo(self.x + dx, self.y + dy)
  end
end

function position:moveTo(ent, x, y, map)
  map = map or self.map
  --printf("[%d] moving to (%d,%d)\n", ent.id, x, y)
  self.x = x
  self.y = y
  if map ~= self.map then
    if self.map then self.map:remove(ent) end
    map:add(ent)
    self.map = map
  end
  return ent:position()
end

function position:position(ent)
  --printf("[%d] reporting position: %d,%d\n", ent.id, self.x, self.y)
  return self.x,self.y,self.map
end

return position
