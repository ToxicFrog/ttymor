local Room = Object:subclass {
  w = 0; h = 0;
  footprint = 0;
}

local tags = {}

-- The <room> tag, in theory, contains information like the dimensions of the
-- room as well as the name. Unfortunately, this information is sometimes
-- untrustworthy; we take only the name and infer the rest from the <row> tags.
function tags:room(xml)
  self.name = xml.attr.name
end

-- A <row> tag contains a single row of terrain; all of the <row> tags together
-- make up the complete terrain of the level, along with any waypoints.
function tags:row(row)
  -- This will result in table indices {0..{w,h}-1}. This is intentional.
  local x = 0
  local y = self.h
  for char in row.attr.text:gmatch('.') do
    if char:match('%d') then
      self.at[char] = {x,y}
      char = '.'
    end
    if char ~= ' ' then
      self.footprint = self.footprint + 1
    end
    self[x] = self[x] or {}
    self[x][y] = char
    x = x+1
  end
  self.w = self.w:max(#row.attr.text:trim())
  self.h = self.h + 1
end

-- The <flags> tag contains all the metadata about the room.
function tags:flags(xml)
  for k,v in pairs(xml.attr) do
    if k == 'minlevel' or k == 'maxlevel' then
      self[k] = tonumber(v)
    else
      self[k] = v == '1' or v == 'true'
    end
  end
end

function Room:locationFromAttr(attr)
  local x,y,at = attr.x,attr.y,attr.at
  if x and y and not at then
    return assert(tonumber(x)),assert(tonumber(y))
  elseif at and not y and not x then
    return unpack((assertf(
      self.at[at],
      "rooms.xml: entity has at=%s but map grid doesn't.",
      at)))
  else
    error("rooms.xml: entity has both x,y and at (or neither)")
  end
end

function tags:customblocker(xml)
  local png = xml.attr.png or xml.attr.pngSprite;
  local x,y = self:location(xml.attr)
  table.insert(self.entities, {
    type = "Wall";
    name = xml.attr.name;
    desc = xml.attr.description;
    x = x; y = y;
    Render = { face = '♦'; png = png };
  })
end

function tags:customengraving(xml)
  local png = xml.attr.png or xml.attr.pngSprite;
  local x,y = self:location(xml.attr)
  table.insert(self.entities, {
    type = "Floor";
    name = xml.attr.name;
    desc = xml.attr.description;
    x = x; y = y;
    Render = { face = '◊'; png = png };
  })
end

--[[
Tags we still need to handle:
W @./dredmor/Room.lua:49] Unrecognized tag in rooms.xml: <action>
W @./dredmor/Room.lua:49] Unrecognized tag in rooms.xml: <condition>
W @./dredmor/Room.lua:49] Unrecognized tag in rooms.xml: <custombreakable>
W @./dredmor/Room.lua:49] Unrecognized tag in rooms.xml: <element>
W @./dredmor/Room.lua:49] Unrecognized tag in rooms.xml: <horde>
W @./dredmor/Room.lua:49] Unrecognized tag in rooms.xml: <loot>
W @./dredmor/Room.lua:49] Unrecognized tag in rooms.xml: <monster>
W @./dredmor/Room.lua:49] Unrecognized tag in rooms.xml: <pedestal>
W @./dredmor/Room.lua:49] Unrecognized tag in rooms.xml: <script>
W @./dredmor/Room.lua:49] Unrecognized tag in rooms.xml: <trap>
]]

-- Unlike most ctors, this takes an XML <room> node as its argument rather than
-- an initializer table.
function Room:__init(root)
  self.at = {}  -- Item positions read from terrain grid; to be filled in by grid reader
  self.entities = {}
  for tag in xml.walk(root) do
    if tags[tag.name] then
      tags[tag.name](self, tag)
    else
      log.warning('Unrecognized tag in rooms.xml: <%s>', tag.name)
    end
  end
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
