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
      "error placing roomtile %s at (%d,%d)", terrain, x, y)
    cell.terrain = terrain
    cell.name = room.name
  end
end

-- Fill in a doorway with wall, since we couldn't create a room there.
local function fillDoor(map, door)
  local x,y = door.x,door.y
  local mx,my = x,y
  if door.dir == 'n' or door.dir == 's' then
    x,mx = x-1,x+1
  else
    y,my = y-1,y+1
  end
  for x=x,mx do
    for y=y,my do
      local cell = map[x][y]
      cell.terrain = 'Wall';
      cell[2] = game.createSingleton('Wall', 'DoorFiller') {
        render = { face = '░' };
      }
    end
  end
end

local function placeDoor(self, door)
  local segments = {}
  local x,y = door.x,door.y
  if door.dir == 'n' or door.dir == 's' then
    segments[1] = { x = x-1; y = y; open = '╸'; shut = '╼' }
    segments[2] = { x = x;   y = y; open = ' '; shut = '━' }
    segments[3] = { x = x+1; y = y; open = '╺'; shut = '╾' }
  else
    segments[1] = { x = x; y = y-1; open = '╹'; shut = '╽' }
    segments[2] = { x = x; y = y;   open = ' '; shut = '┃' }
    segments[3] = { x = x; y = y+1; open = '╻'; shut = '╿' }
  end
  for _,segment in ipairs(segments) do
    self[segment.x][segment.y].terrain = 'Floor'
    local door = self:create 'Door' {
      door = {
        face_open = segment.open;
        face_shut = segment.shut;
      };
      position = {
        x = segment.x; y = segment.y; z = self.depth;
      }
    }
    self[segment.x][segment.y][2] = door
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

local function placeObjects(self)
  for _,obj in ipairs(self._objects) do
    local ent = self:create 'TestObject' {
      render = {
        face = (obj.type or '?'):sub(1,1);
      };
      position = {
        x = obj.x;
        y = obj.y;
      }
    }
    self:placeAt(ent, obj.x, obj.y)
  end
  self._objects = nil
end

local opposite = { n='s'; s='n'; e='w'; w='e'; }

local function isRoomCompatible(self, door, doorway)
  local ox = doorway.x - door.x - 1
  local oy = doorway.y - door.y - 1
  if not in_bounds(self, ox, oy, door.room.w, door.room.h) then
    return false
  end

  for x,y,cell in door.room:cells(ox, oy) do
    local mapcell = self[x][y]
    if mapcell.terrain and (mapcell.terrain ~= cell or mapcell.terrain ~= 'Wall') then
      -- collision with existing terrain
      return false
    end
  end

  return true
end

return function(self, w, h)
  self.w, self.h = w,h
  for x=1,self.w do
    self[x] = {}
    for y=1,self.h do
      self[x][y] = {}
    end
  end

  self._doors = {}
  self._objects = {}

  local function pushDoor(door, x, y)
    table.insert(self._doors, {
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

  while #self._doors > 0 do
    local doorway = table.remove(self._doors, 1)
    log.debug('checking door %s', repr(doorway))
    -- find a compatible random room
    for i=1,5 do
      local door = dredmor.randomDoor(doorway.dir)
      if isRoomCompatible(self, door, doorway) then
        -- place it
        local ox,oy = doorway.x - door.x, doorway.y - door.y
        placeRoom(self, door.room, ox-1, oy-1)
        for newdoor in door.room:doors() do
          if newdoor ~= door then pushDoor(newdoor, ox, oy) end
        end
        placeDoor(self, doorway)
        for _,obj in ipairs(door.room.contents) do
          obj = table.copy(obj)
          if not obj.x or not obj.y then
            log.debug("Object has no location! %s", repr(obj))
          else
            obj.x = ox + obj.x
            obj.y = oy + obj.y
            table.insert(self._objects, obj)
          end
        end
        doorway = nil
        break
      else
        log.debug('rejected %s', door.room.name)
      end
    end
    -- Couldn't find a room. Close the door.
    if doorway then
      fillDoor(self, doorway)
    end
  end

  createTerrain(self)
  placeObjects(self)
end
