local tags = require 'dredmor.room-tags'
local Room = Object:subclass {
  w = 0; h = 0;
  footprint = 0;
}

-- Unlike most ctors, this takes an XML <room> node as its argument rather than
-- an initializer table.
function Room:__init(root)
  self._at = {}  -- Item positions read from terrain grid; to be filled in by grid reader
  self._entities = {}
  self._doors = {}
  for tag in xml.walk(root) do
    if tags[tag.name] then
      tags[tag.name](self, tag)
    else
      log.warning('Unrecognized tag in rooms.xml: <%s>', tag.name)
    end
  end

  -- For each door, replace the terrain tiles covering the door (#d# or #D#)
  -- with 'D' tiles. These behave the same as ' ' except for the purposes of
  -- collision detection.
  for x,y,dir in self:doors() do
    if dir == 'n' or dir == 's' then
      self[x-1][y],self[x][y],self[x+1][y] = 'D','D','D'
    else
      self[x][y-1],self[x][y],self[x][y+1] = 'D','D','D'
    end
  end
end

-- If this room is at (0,0), and other is a room at (x,y), do they collide with
-- each other?
-- Note that just checking if the bounding boxes overlap isn't enough, since a
-- room may have fancy edges.
-- Furthermore, the map generator actually expects rooms to overlap by 1 tile;
-- that is, the connected doors are merged into one door. So, if two rooms have
-- terrain in the same square, but that terrain is a wall or door, that also
-- doesn't count as a collision.
-- Any other terrain type, or disagreeing on what the terrain type is, does.
function Room:collidesWith(other, x, y)
  -- Quick check to see if the bounding boxes intersect.
  if x+other.w <= 0 or self.w <= x or y+other.h <= 0 or self.h <= y
  then return false end

  for my_x = x:max(0),self.w:min(x+other.w)-1 do
    for my_y = y:max(0),self.h:min(y+other.h)-1 do
      local my_tile,their_tile = self[my_x][my_y], other[my_x - x][my_y - y]
      -- If either tile is void, it doesn't matter what the other is; they don't
      -- collide.
      if my_tile == ' ' or their_tile == ' ' then goto continue end
      -- If neither are void, any disagreement means a collision.
      if my_tile ~= their_tile then return true end
      -- Even if they agree, only walls and doors are allowed to overlap.
      if my_tile ~= '#' and my_tile ~= 'D' and my_tile ~= ' ' then return true end
      ::continue::
    end
  end

  return false
end

-- Return an iterator over all doors, as (x,y,dir) tuples. dir is the direction
-- you move when stepping out of the room, so dir == 'n' means the room is on the
-- northern wall of the room.
-- If called with an argument, only doors facing in that direction will be returned.
function Room:doors(dir)
  return coroutine.wrap(function()
    for _,d in ipairs(self._doors) do
      if not dir or d.dir == dir then
        coroutine.yield(d.x, d.y, d.dir)
      end
    end
  end)
end

do
return Room
end

-- Returns an iterator over all doors in this room. If 'dir' is specified, yields
-- only doors facing in that direction.
function Room:doors(dir)
  return coroutine.wrap(function()
    for _,d in ipairs(self._doors) do
      if not dir or d.dir == dir then
        coroutine.yield(d)
      end
    end
  end)
end

-- Returns an iterator over all cells in the room, yielding (x,y,cell) for each
-- one.
-- The ox,oy values are added to each cell as it's emitted; this can be used to
-- easily iterate the cells in map coordinate space, for example.
-- All coordinates returned are in the range (0,0) to (w-1,h-1).
function Room:cells(ox,oy)
  ox = ox or 0
  oy = oy or 0
  return coroutine.wrap(function()
    for x=0,self.w-1 do
      for y=0,self.h-1 do
        coroutine.yield(x+ox,y+oy,self[x][y] or false)
      end
    end
  end)
end

-- Handlers for terrain types that require special treatment.
local function shop_door(self, x, y)
  self.shop_door = {x,y}
  self[x][y] = 'Floor'
end

local function doorNS(self, x, y)
  table.insert(self._doors,
    { x = x; y = y; room = self; dir = (y == 0 and 'n' or 's'); })
  self[x-1][y],self[x][y],self[x+1][y] = false,false,false
end
local function doorEW(self, x, y)
  table.insert(self._doors,
    { x = x; y = y; room = self; dir = (x == 0 and 'w' or 'e'); })
  self[x][y-1],self[x][y],self[x][y+1] = false,false,false
end

-- table mapping terrain chars to cell contents
-- each one is either a table, in which case the first value is the EntityType of the
-- terrain to use and everything else is to be added to the object table with the
-- (x,y) of the tile, or is a function, in which case it's called and passed the
-- room object and (x,y) and can do whatever it likes.
-- an EntityType of false means that that cell is empty space.
local terrain = {
  ['#'] = { 'Wall' }; ['.'] = { 'Floor' }; [' '] = { false };
  W = { 'Water' }; G = { 'Goo' }; I = { 'Ice' }; L = { 'Lava' };
  ['!'] = { 'Floor', 'FakeWall' }; ['X'] = { 'InvisibleWall' };
  P = { 'Wall', 'Tapestry' };
  ['^'] = { 'Floor', 'Carpet' };
  ['@'] = { 'Wall', 'DecorativeBlocker' };
  D = doorNS; d = doorEW;
  S = { 'Floor', 'Shopkeeper' };
  i = { 'Wall', 'ShopPedestal' };
  s = shop_door;
}

-- Room postprocessor. There's a bunch of things that have to happen here, eventually,
-- but for now the most important ones are this:
-- - beacons (1-9) need to be located, replaced with '.', and entered into the location array
-- - doors need to be located, their direction determined, and entered into the doors array
-- - terrain needs to be replaced with the EntityType of the corresponding terrain
-- - everything else needs to be added to the room.contents array and replaced with terrain
local function postprocess(self)
  for x,y,cell in self:cells() do
    if cell == false then
      self[x][y] = false
    elseif cell:match('%d') then -- location marker
      self._locations[tonumber(cell)] = { x=x, y=y }
      self[x][y] = 'Floor'
    elseif terrain[cell] then
      local content = terrain[cell]
      if type(content) == 'table' then
        self[x][y] = content[1]
        for i=2,#content do
          table.insert(self.contents, {_type = "Terrain"; name=content[i], x=x, y=y})
        end
      else
        content(self, x, y)
      end
    else
      error('Unhandled terrain cell type "%s" reading self %s"',
        cell, self.name)
    end
  end
  for i,obj in ipairs(self.contents) do
    if obj.at then
      local at = assertf(self._locations[obj.at], "couldn't find location %s in room %s", obj.at, self.name)
      obj.x,obj.y = at.x,at.y
      obj.at = nil
    end
  end
  self._locations = nil
end

return function(t)
  setmetatable(t, Room)
  postprocess(t)
  return t
end
