-- Implementation of map generation.
-- The function returned by this library becomes the Map:generate() method.

settings.Category {
  name = 'Map Generation';
  per_game = true;
  hidden = true;
}

settings.Int {
  category = 'Map Generation';
  name = 'Retries Per Room';
  value = 10; min = 1, max = 20;
  help = 'Number of times to try placing a room before giving up.';
};
settings.Float {
  category = 'Map Generation';
  name = 'Map Density';
  value = 0.6; min = 0.0, max = 1.0;
  help = 'Minimum proportion of the map that needs to be filled.';
};

local MapGen = {}

function MapGen:inBounds(x, y, w, h)
  return x >= 0 and y >= 0 and x+w < self.map.w and y+h < self.map.h
end

local opposite = { n='s'; s='n'; e='w'; w='e'; }

function MapGen:pushDoor(door, x, y)
  table.insert(self.doors, {
    x = x+door.x; y = y+door.y;
    dir = opposite[door.dir]
  })
end

function MapGen:pullDoor()
  return table.remove(self.doors, 1)
end

-- Copy a single cell into place, with checks
local function copyTerrain(cell, terrain)
  if not terrain then return end
  assertf(not cell[1] or (cell[1] == 'Wall' and terrain == 'Wall'),
    "error placing terrain %s: %s", terrain, cell[1])
  cell[1] = terrain
end

-- Instantiate and place an object from a room's object table
function MapGen:placeObject(obj, ox, oy)
  if not obj.x then
    log.debug("Object has no location! %s", repr(obj))
    return
  end

  local x,y = obj.x+ox,obj.y+oy
  local ent = {
    type = 'TestObject';
    name = obj.name or obj.type or obj._type or "???";
    Render = {
      face = (obj.type or '?'):sub(1,1);
    };
    Position = {
      x = x; y = y;
    }
  }
  if not self[x][y][1] then
    log.debug("Object %s at (%d,%d) in void!", ent, x, y)
    ent.Render.colour = { 255, 0, 0 }
    ent.Render.style = 'v'
  end
  table.insert(self[x][y], self.map:create(ent))
end

-- Place an entire room into the map, create and place all of its objects, and
-- enqueue all of its doors.
function MapGen:placeRoom(room, ox, oy)
  log.debug("Placing %s (%dx%d) at (%d,%d)",
      room.name, room.w, room.h, ox, oy)
  assertf(self:inBounds(ox, oy, room.w, room.h),
    "out of bounds room placement: %s (%dx%d) at (%d,%d)",
    room.name, room.w, room.h, ox, oy)

  -- Generate a random name for this room
  -- Room names are 'The [adjective] <architecture> [of <plural-noun>]'
  -- At least one of adjective or plural-noun must appear; both are permitted.
  local words = math.random(1,3)
  local name
  if words == 1 then
    -- adjective, no noun
    name = 'The %s %s' % { dredmor.text 'adjective', dredmor.text 'architecture' }
  elseif words == 2 then
    -- noun, no adjective
    name = 'The %s of %s' % { dredmor.text 'architecture', dredmor.text('noun', 'plural') }
  else
    -- both
    name = 'The %s %s of %s' % {
      dredmor.text 'adjective', dredmor.text 'architecture', dredmor.text('noun', 'plural')
    }
  end

  -- Copy the terrain into the map.
  for x,y,terrain in room:cells(ox,oy) do
    local cell = self[x][y]
    cell.name = name
    copyTerrain(cell, terrain)
  end

  -- Copy the objects into the map.
  for _,obj in ipairs(room.contents) do
    self:placeObject(obj, ox, oy)
  end

  -- Push all doors from that room into the queue.
  for door in room:doors() do
    self:pushDoor(door, ox, oy)
  end

  -- Strike the room from the list if it's a once-per-level room.
  if room.flags.special then
    self.excluded[room] = true
  end

  -- Update the density calculation.
  self.density = self.density + (room.w*room.h)/(self.map.w*self.map.h)
end

-- Fill in a doorway with wall, since we couldn't create a room there.
function MapGen:fillDoor(door)
  local x,y = door.x,door.y
  local mx,my = x,y
  if door.dir == 'n' or door.dir == 's' then
    x,mx = x-1,x+1
  else
    y,my = y-1,y+1
  end
  for x=x,mx do
    for y=y,my do
      local cell = self[x][y]
      cell[1] = 'Wall';
      -- Temporary addition so that places where doors were filled in stand out.
      -- For debugging the map generator.
      cell[2] = game.createSingleton 'DoorFiller' {
        type = 'Wall';
        Render = { face = '░' };
      }
    end
  end
end

-- Lay down a doorway -- floor with three door segments on top of it.
function MapGen:placeDoor(door)
  local segments = {}
  local x,y = door.x,door.y
  if door.dir == 'n' or door.dir == 's' then
    segments[1] = { x = x-1; y = y; open = '╸'; shut = '╼' }
    segments[2] = { x = x;   y = y; open = '.'; shut = '━' }
    segments[3] = { x = x+1; y = y; open = '╺'; shut = '╾' }
  else
    segments[1] = { x = x; y = y-1; open = '╹'; shut = '╽' }
    segments[2] = { x = x; y = y;   open = '.'; shut = '┃' }
    segments[3] = { x = x; y = y+1; open = '╻'; shut = '╿' }
  end
  for i,segment in ipairs(segments) do
    local door = self.map:create {
      type = 'Door';
      Door = {
        face_open = segment.open;
        face_shut = segment.shut;
      };
      Position = {
        x = segment.x; y = segment.y; z = self.map.depth;
      }
    }
    self[segment.x][segment.y][1] = 'Floor'
    self[segment.x][segment.y][2] = door
    segments[i] = door
  end
  for i,door in ipairs(segments) do
    door.Door.segments = table.copy(segments, 1)
  end
end

-- The map grid is initially created using strings in place of the terrain.
-- This function converts those strings into appropriate singleton entities.
function MapGen:createTerrain()
  for x=0,self.map.w-1 do
    for y=0,self.map.h-1 do
      local cell = self[x][y]
      if type(cell[1]) == 'string' then
        cell[1] = game.createSingleton('terrain:'..cell[1]) { type = cell[1] }
      elseif cell[1] == false then
        cell[1] = nil
      end
    end
  end
end

-- Check if the room associated with door can be placed on the map such that
-- door and target are connected.
-- This is true if the room doesn't go OOB and doesn't collide with any existing
-- terrain. The terrain collision check implicitly checks that the door
-- directions match up, since if they don't the room interiors will overlap.
function MapGen:isRoomCompatible(door, target)
  local ox = target.x - door.x
  local oy = target.y - door.y
  if not self:inBounds(ox, oy, door.room.w, door.room.h) then
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

-- Place a room connected to the target_door.
function MapGen:placeRoomAtDoor(room, door, target_door)
  -- calculate offsets based on position of target_door
  local ox,oy = target_door.x - door.x, target_door.y - door.y
  self:placeRoom(room, ox, oy)
  self:placeDoor(target_door)
end

-- Return a random non-excluded room from the room pool.
function MapGen:randomRoom()
  local room = self.room_pool[math.random(1, #self.room_pool)]
  if self.excluded[room] then
    return self:randomRoom()
  end
  return room
end

-- Find a room that can attach to the target door. Return the room, then the
-- door that will attach. If multiple doors in this room can attach to the
-- target, picks one at random.
-- A room counts as attachable if it has a door pointing in the right direction
-- and doesn't collide with any existing terrain or go OOB.
function MapGen:findCompatibleRoom(target)
  local tries = 5
  for i=1,settings.map_generation.retries_per_room do
    local room = self:randomRoom()
    local doors = {}
    for door in room:doors() do
      if self:isRoomCompatible(door, target) then
        table.insert(doors, door)
      end
    end
    if #doors > 0 then
      local door = doors[math.random(1, #doors)]
      return door.room,door
    end
  end
end

local function filter(depth)
  return function(room)
    return (room.flags.minLevel or 0) <= depth
       and depth <= (room.flags.maxLevel or math.huge)
  end
end

function MapGen:generate(map, starting_room)
  self.map = map

  local w,h = map.w,map.h

  for x=0,w-1 do
    self[x] = {}
    for y=0,h-1 do
      self[x][y] = {}
    end
  end

  self.density = 0.0
  self.doors = {}
  self.excluded = {}
  self.entities = {}
  self.room_pool = dredmor.rooms(filter(map.depth))

  -- place the first room in the middle of the map
  local room
  if starting_room then
    room = assertf(dredmor.room(starting_room),
        "Couldn't find room %s to start map generation with",
        starting_room)
  else
    room = self:randomRoom()
  end
  local x = (w/2 - room.w/2):floor()
  local y = (h/2 - room.h/2):floor()
  self:placeRoom(room, x, y)

  local count = 1
  for target_door in self.pullDoor,self do
    -- find a compatible random room
    local room,door = self:findCompatibleRoom(target_door)
    if room then
      count = count + 1
      self:placeRoomAtDoor(room, door, target_door)
    elseif not self[target_door.x][target_door.y][2] then
      self:fillDoor(target_door)
    end
  end

  -- Restart the whole process if we didn't hit the target density.
  if self.density < settings.map_generation.map_density then
    log.info("Restarting map generation: density %0.2f < target %0.2f",
        self.density, settings.map_generation.map_density)
    return self:generate(map, starting_room)
  else
    log.info("Generated map with %d rooms and %0.2f density",
        count, self.density)
  end

  -- finalize
  self:createTerrain()
  for x,col in ipairs(self) do
    map[x] = col
  end
  map.entities = self.entities
end

return function()
  return setmetatable({}, {__index = MapGen})
end
