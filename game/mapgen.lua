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

-- Copy a single cell into place, with checks
local function copyTerrain(cell, terrain)
  if not terrain then return end
  assertf(not cell[1] or (cell[1] == 'Wall' and terrain == 'Wall'),
    "error placing terrain %s: %s", terrain, cell[1])
  cell[1] = terrain
end

-- Instantiate and place an object from a room's object table
local function placeObject(self, obj, ox, oy)
  if not obj.x then
    log.debug("Object has no location! %s", repr(obj))
    return
  end

  local x,y = obj.x+ox,obj.y+oy
  local ent = {
    name = obj.name or obj.type or obj._type or "???";
    render = {
      face = (obj.type or '?'):sub(1,1);
    };
    position = {
      x = x; y = y;
    }
  }
  if not self[x][y][1] then
    log.debug("Object %s at (%d,%d) in void!", ent, x, y)
    ent.render.colour = { 255, 0, 0 }
    ent.render.style = 'v'
  end
  self:placeAt(self:create('TestObject')(ent), x, y)
end

-- Place an entire room into the map, create and place all of its objects, and
-- enqueue all of its doors.
local function placeRoom(self, room, ox, oy)
  log.debug("Placing %s (%dx%d) at (%d,%d)",
      room.name, room.w, room.h, ox, oy)
  assertf(in_bounds(self, ox, oy, room.w, room.h),
    "out of bounds room placement: %s (%dx%d) at (%d,%d)",
    room.name, room.w, room.h, ox, oy)

  -- Copy the terrain into the map.
  for x,y,terrain in room:cells(ox,oy) do
    local cell = self[x][y]
    cell.name = room.name
    copyTerrain(cell, terrain)
  end

  -- Copy the objects into the map.
  for _,obj in ipairs(room.contents) do
    placeObject(self, obj, ox, oy)
  end

  -- Push all doors from that room into the queue.
  for door in room:doors() do
    pushDoor(self, door, ox, oy)
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
  for x,y,cell in self:cells() do
    if type(cell[1]) == 'string' then
      cell[1] = game.createSingleton(cell[1], 'terrain:'..cell[1]) {}
    elseif cell[1] == false then
      cell[1] = nil
    end
  end
end

local function isRoomCompatible(self, door, target)
  local ox = target.x - door.x
  local oy = target.y - door.y
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
  placeRoom(self, room, ox, oy)
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
  for x=0,self.w-1 do
    self[x] = {}
    for y=0,self.h-1 do
      self[x][y] = {}
    end
  end

  self._doors = {}

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
    -- find a compatible random room
    local room,door = findCompatibleRoom(self, target_door)
    if room then
      placeRoomAtDoor(self, room, door, target_door)
    elseif not self[target_door.x][target_door.y][2] then
      fillDoor(self, target_door)
    end
  end

  createTerrain(self)
end
