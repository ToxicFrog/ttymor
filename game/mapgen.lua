-- Implementation of map generation.
-- The function returned by this library becomes the Map:generate() method.

local function in_bounds(map, x, y, w, h)
  return x >= 0 and y >= 0 and x+w < map.w and y+h < map.h
end

local function placeRoom(map, room, ox, oy)
  log.debug("Placing %s (%dx%d) at (%d,%d)",
      room.name, room.w, room.h, ox, oy)
  assertf(in_bounds(map, ox, oy, room.w, room.h),
    "out of bounds room placement: %s (%dx%d) at (%d,%d)",
    room.name, room.w, room.h, ox, oy)
  for x,y,terrain in room:cells(ox,oy) do
    local cell = map[x][y]
    assertf(not cell.terrain or (cell.terrain == 'Wall' and terrain == 'Wall'),
      "error placing roomtile (%d,%d) on maptile (%d,%d)", x,y,x+ox-1,y+oy-1)
    cell.terrain = terrain
    cell.name = room.name
  end
end

local function createTerrain(self)
  for x=1,self.w do
    for y=1,self.h do
      local cell = self[x][y]
      if cell.terrain then
        assert(type(cell.terrain) == 'string', repr(cell))
        cell[1] = game.createSingleton(cell.terrain, 'terrain:'..cell.terrain) {}
      end
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

  for x,y,cell in door.room:cells() do
    local mapcell = self[ox+x][oy+y]
    if mapcell.terrain and (mapcell.terrain ~= cell or mapcell.terrain ~= 'Wall') then
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
  placeRoom(self, room, x, y)
  for door in room:doors() do pushDoor(door, x+1, y+1) end

  while #doors > 0 do
    local doorway = table.remove(doors, 1)
    log.debug('checking door %s', repr(doorway))
    -- find a compatible random room
    for i=1,20 do
      local door = dredmor.randomDoor(doorway.dir)
      if isRoomCompatible(self, door, doorway) then
        -- place it
        placeRoom(self, door.room, doorway.x - door.x - 1, doorway.y - door.y - 1)
        for newdoor in door.room:doors() do
          if newdoor ~= door then pushDoor(newdoor, doorway.x - door.x, doorway.y - door.y) end
        end
        break
      else
        log.debug('rejected %s', door.room.name)
      end
    end
    -- create door objects
    -- push doors from that room
  end

  createTerrain(self)
  do return end
end
