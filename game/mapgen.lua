-- Implementation of map generation.
-- The function returned by this library becomes the Map:generate() method.

local function in_bounds(map, x, y, w, h)
  return x > 0 and y > 0 and x+w <= map.w and y+h <= map.h
end

local function tiles(self)
  local function iter()
    for x=1,self.w do
      for y=1,self.h do
        coroutine.yield(x,y,self[x][y])
      end
    end
  end
  return coroutine.wrap(iter)
end

local function spliceRoom(map, room, ox, oy)
  assert(in_bounds(map, ox, oy, room.w, room.h))
  for x=1,room.w do
    for y=1,room.h do
      map[x+ox-1][y+oy-1] = { terrain = room.map[x][y]; name = room.name }
    end
  end
end

local function createTerrain(self)
  for x,y,tile in tiles(self) do
    if tile.terrain then
      assert(type(tile.terrain) == 'string', repr(tile))
      tile[1] = game.createSingleton(tile.terrain, 'terrain:'..tile.terrain) {}
    end
  end
end

local function randomRoom()
  local rooms = dredmor.rooms()
  return rooms[math.random(1, #rooms)]
end

return function(self, w, h)
  self.w, self.h = w,h
  for x=1,self.w do
    self[x] = {}
    for y=1,self.h do
      self[x][y] = {}
    end
  end

  local x,y = 1,1
  while true do
    local room = randomRoom()
    if x + room.w > w then
      x = 1
      y = y + room.h
    end
    if not in_bounds(self, x, y, room.w, room.h) then
      createTerrain(self)
      return
    else
      spliceRoom(self, room, x, y)
      x = x + room.w
    end
  end
end
