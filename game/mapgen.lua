-- Implementation of map generation.
-- The function returned by this library becomes the Map:generate() method.

local function in_bounds(map, x, y, w, h)
  return x >= 0 and y >= 0 and x+w < map.w and y+h < map.h
end

local function cells(self)
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
  print("Placing %s (%dx%d) at (%d,%d)",
      room.name, room.w, room.h, ox, oy)
  assertf(in_bounds(map, ox, oy, room.w, room.h),
    "out of bounds room placement: %s (%dx%d) at (%d,%d)",
    room.name, room.w, room.h, ox, oy)
  for x=1,room.w do
    for y=1,room.h do
      local cell = map[x+ox][y+oy]
      assertf(not cell.terrain or (cell.terrain == 'Wall' and room[x][y] == 'Wall'),
        "error placing roomtile (%d,%d) on maptile (%d,%d)", x,y,x+ox-1,y+oy-1)
      cell.terrain = room[x][y]
      cell.name = room.name
    end
  end
end

local function createTerrain(self)
  for x,y,tile in cells(self) do
    if tile.terrain then
      assert(type(tile.terrain) == 'string', repr(tile))
      tile[1] = game.createSingleton(tile.terrain, 'terrain:'..tile.terrain) {}
    end
  end
end

local opposite = { n='s'; s='n'; e='w'; w='e'; }

local function isRoomCompatible(self, door, doorway)
  local ox = doorway.x - door.x - 1
  local oy = doorway.y - door.y - 1
  if not in_bounds(self, ox, oy, door.room.w, door.room.h) then
    return false
  end

  for x,y,tile in cells(door.room) do
    local maptile = self[ox+x][oy+y]
    if maptile.terrain and (maptile.terrain ~= tile or maptile.terrain ~= 'Wall') then
      -- collision with existing terrain
      return false
    end
  end

  return true
end

-- doors
-- ╸ ╺ open
-- ╼━╾ closed
-- ╹ ╽
--   ┃
-- ╻ ╿

return function(self, w, h)
  self.w, self.h = w,h
  for x=1,self.w do
    self[x] = {}
    for y=1,self.h do
      self[x][y] = {}
    end
  end

  local doors = {}
  local function pushDoor(door, x, y)
    table.insert(doors, {
      x = x+door.x; y = y+door.y;
      dir = opposite[door.dir]
    })
  end

  -- place the first room in the middle of the map
  local room = dredmor.randomRoom()
  local x = (self.w/2 - room.w/2):floor()
  local y = (self.h/2 - room.h/2):floor()

  -- push all doors from that room into the queue
  spliceRoom(self, room, x, y)
  for door in room:doors() do pushDoor(door, x+1, y+1) end

  while #doors > 0 do
    local doorway = table.remove(doors, 1)
    print('checking door', repr(doorway))
    -- find a compatible random room
    for i=1,20 do
      local door = dredmor.randomDoor(doorway.dir)
      if isRoomCompatible(self, door, doorway) then
        -- place it
        spliceRoom(self, door.room, doorway.x - door.x - 1, doorway.y - door.y - 1)
        for newdoor in door.room:doors() do
          if newdoor ~= door then pushDoor(newdoor, doorway.x - door.x, doorway.y - door.y) end
        end
        break
      else
        print('rejected '..door.room.name)
      end
    end
    -- create door objects
    -- push doors from that room
  end

  createTerrain(self)
  do return end
end
