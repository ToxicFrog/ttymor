local Room = {}
Room.__index = Room

-- Returns an iterator over all doors in this room. If 'dir' is specified, yields
-- only doors facing in that direction.
function Room:doors(dir)
  return coroutine.wrap(function()
    for i,d in ipairs(self._doors) do
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
-- Note that the default values of (0,0) result in room coordinates ranging from
-- (1,1) to (w,h).
function Room:cells(ox,oy)
  ox = ox or 0
  oy = oy or 0
  return coroutine.wrap(function()
    for x=1,self.w do
      for y=1,self.h do
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
    { x = x-1; y = y-1; room = self; dir = (y == 1 and 'n' or 's'); })
  self[x-1][y],self[x][y],self[x+1][y] = false,false,false
end
local function doorEW(self, x, y)
  table.insert(self._doors,
    { x = x-1; y = y-1; room = self; dir = (x == 1 and 'w' or 'e'); })
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
      self._locations[cell] = { x=x-1, y=y-1 }
      self[x][y] = 'Floor'
    elseif terrain[cell] then
      local content = terrain[cell]
      if type(content) == 'table' then
        self[x][y] = content[1]
        for i=2,#content do
          table.insert(self.contents, {_type = "Terrain"; name=content[i]})
        end
      else
        content(self, x, y)
      end
    else
      errorf('Unhandled terrain cell type "%s" reading self %s"',
        cell, self.name)
    end
  end
  for i,obj in ipairs(self.contents) do
    if obj.at then
      local at = assertf(self._locations[obj.at], "couldn't find location %s in room %s", obj.at, self.name)
      obj.x,obj.y = at[1],at[2]
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
