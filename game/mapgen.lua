-- Implementation of map generation.
-- The function returned by this library becomes the Map:generate() method.

local function in_bounds(map, x, y, w, h)
  return x >= 0 and y >= 0 and x+w < map.w and y+h < map.h
end

local opposite = { n='s'; s='n'; e='w'; w='e'; }

local function pushDoor(self, door, x, y)
  table.insert(self._doors, {
    x = x+door.x; y = y+door.y;
    dir = opposite[door.dir]
  })
end

local function pullDoor(self)
  return table.remove(self._doors, 1)
end

local function placeRoom(self, room, ox, oy)
  log.debug("Placing %s (%dx%d) at (%d,%d)",
      room.name, room.w, room.h, ox, oy)
  assertf(in_bounds(self, ox, oy, room.w, room.h),
    "out of bounds room placement: %s (%dx%d) at (%d,%d)",
    room.name, room.w, room.h, ox, oy)

  -- Copy the terrain into the map.
  for x,y,terrain in room:cells(ox,oy) do
    if terrain then
      local cell = self[x][y]
      assertf(not cell[1] or not terrain or (cell[1] == 'Wall' and terrain == 'Wall'),
        "error placing roomtile %s at (%d,%d): %s", terrain, x, y, cell[1])
      cell[1] = terrain
      cell.name = room.name
    end
  end

  -- Copy the objects into the map.
  for _,obj in ipairs(room.contents) do
    obj = table.copy(obj)
    if not obj.x or not obj.y then
      log.debug("Object has no location! %s", repr(obj))
    else
      obj.x = ox + obj.x
      obj.y = oy + obj.y
      table.insert(self._objects, obj)
    end
  end

  -- push all doors from that room into the queue
  for door in room:doors() do
    pushDoor(self, door, ox+1, oy+1)
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
      cell[1] = 'Wall';
      -- Temporary addition so that places where doors were filled in stand out.
      -- For debugging the map generator.
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
    print(repr(segment))
    self[segment.x][segment.y][1] = 'Floor'
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
      if cell[1] then
        assert(type(cell[1]) == 'string', repr(cell))
        cell[1] = game.createSingleton(cell[1], 'terrain:'..cell[1]) {}
      end
    end
  end
end

local function placeObjects(self)
  for _,obj in ipairs(self._objects) do
    local ent = self:create 'TestObject' {
      name = obj.name or obj.type or obj._type or "???";
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

local function isRoomCompatible(self, door, doorway)
  local ox = doorway.x - door.x - 1
  local oy = doorway.y - door.y - 1
  if not in_bounds(self, ox, oy, door.room.w, door.room.h) then
    return false
  end

  for x,y,cell in door.room:cells(ox, oy) do
    local mapcell = self[x][y]
    if mapcell[1] and (mapcell[1] ~= cell or mapcell[1] ~= 'Wall') then
      -- collision with existing terrain
      return false
    end
  end

  return true
end

local function placeRoomAtDoor(self, room, door, target_door)
  -- calculate offsets based on position of target_door
  local ox,oy = target_door.x - door.x, target_door.y - door.y
  placeRoom(self, room, ox-1, oy-1)
  placeDoor(self, target_door)
end

local function findCompatibleRoom(self, target)
  for i=1,5 do
    local door = dredmor.randomDoor(target.dir)
    if isRoomCompatible(self, door, target) then
      return door.room,door
    end
  end
end

return function(self, w, h, room)
  self.w, self.h = w,h
  for x=1,self.w do
    self[x] = {}
    for y=1,self.h do
      self[x][y] = {}
    end
  end

  self._doors = {}
  self._objects = {}

  -- place the first room in the middle of the map
  if room then
    room = dredmor.room(room)
  else
    room = dredmor.randomRoom()
  end
  local x = (self.w/2 - room.w/2):floor()
  local y = (self.h/2 - room.h/2):floor()
  placeRoom(self, room, x, y)

  for target_door in pullDoor,self do
    log.debug('checking door %s', repr(target_door))
    -- find a compatible random room
    local room,door = findCompatibleRoom(self, target_door)
    if room then
      placeRoomAtDoor(self, room, door, target_door)
    elseif not self[target_door.x][target_door.y][2] then
      fillDoor(self, target_door)
    end
  end

  createTerrain(self)
  placeObjects(self)
end
