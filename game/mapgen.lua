-- Implementation of map generation.
-- The function returned by this library becomes the Map:generate() method.

local function in_bounds(map, x, y, w, h)
  return x > 0 and y > 0 and x+w <= map.w and y+h <= map.h
end

local function spliceRoom(map, room, ox, oy)
  assert(in_bounds(map, ox, oy, room.w, room.h))
  for y=oy,oy+room.h-1 do
    local row = room.map[y-oy+1]
    assertf(row, "error reading room at row %d: %s", y-oy+1, repr(room))
    for x=ox,ox+room.w-1 do
      local cell = row:sub(x-ox+1,x-ox+1)
      if cell == '#' then
        map[x][y] = { game.createSingleton('Wall', 'tile:#') {} }
      elseif cell == '.' then
        map[x][y] = { game.createSingleton('Floor', 'tile:.') {} }
      else
        map[x][y] = {
          game.createSingleton('Floor', 'tile:.') {};
          map:create 'TestObject' { render = { face = cell } };
        }
      end
    end
  end
end

local function randomRoom()
  local rooms = dredmor.rooms()
  return rooms[math.random(1, #rooms)]
end

return function(self, w, h)
  self.w, self.h = w,h
  local wall = self:create 'Wall' {}
  local floor = self:create 'Floor' {}
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
      return
    else
      spliceRoom(self, room, x, y)
      x = x + room.w
    end
  end
end
