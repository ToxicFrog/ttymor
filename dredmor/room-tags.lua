-- Readers for all the various tags you find inside a <room> tag in rooms.xml.
-- This is used by Room to turn a <room> DOM node into an actual room definition.
--
-- These are all called as if methods on Room, so they are defined with : and
-- the self argument is the Room being constructed.

local tags = {}

-- The <room> tag, in theory, contains information like the dimensions of the
-- room as well as the name. Unfortunately, this information is sometimes
-- untrustworthy; we take only the name and infer the rest from the <row> tags.
function tags:room(xml)
  self.name = xml.attr.name
end

local function addDoor(self, x, y, ns)
  local dir
  if ns then -- door faces either north or south
    dir = (y == 0 or self[x][y-1] == ' ') and 'n' or 's'
  else
    dir = (x == 0 or self[x-1][y] == ' ') and 'w' or 'e'
  end
  table.insert(self._doors, { x=x, y=y, dir=dir })
end

-- A <row> tag contains a single row of terrain; all of the <row> tags together
-- make up the complete terrain of the level, along with any waypoints.
function tags:row(row)
  -- This will result in table indices {0..{w,h}-1}. This is intentional.
  local x = 0
  local y = self.h
  for char in row.attr.text:gmatch('.') do

    -- Waypoints are single digits. They behave like floors but will have an
    -- item placed on them later.
    if char:match('%d') then
      self._at[char] = {x,y}
      char = '.'
    end

    -- Doors behave like either walls or floors depending on whether they're
    -- connected to another room. They get their own special table.
    if char:match('[dD]') then
      addDoor(self, x, y, char == 'D')
      char = 'D'
    end

    -- ' ' is empty space. Anything that isn't ' ' contributes to the room's footprint,
    -- even walls.
    if char ~= ' ' then
      self.footprint = self.footprint + 1
    end

    self[x] = self[x] or {}
    self[x][y] = char
    x = x+1
  end
  self.w = self.w:max(#row.attr.text)
  self.h = self.h + 1
end

-- The <flags> tag contains all the metadata about the room.
function tags:flags(xml)
  for k,v in pairs(xml.attr) do
    if k == 'minlevel' or k == 'maxlevel' then
      self[k] = tonumber(v)
    elseif type(k) == 'string' then
      -- k may be a number, since xml.attr is both a map of key => value and
      -- an array of (key,value) pairs.
      self[k] = v == '1' or v == 'true'
    end
  end
end

-- Given an entity tag's attribute map, return the (x,y) coordinates of the
-- entity. If the entity has x= and y= attributes, we use those. If it as at=,
-- the value is assumed to be the name of a waypoint that was read earlier from
-- the <row> tags.
local function locationFromAttr(self, attr)
  local x,y,at = attr.x,attr.y,attr.at
  if x and y and not at then
    return assert(tonumber(x)),assert(tonumber(y))
  elseif at and not y and not x then
    return unpack((assertf(
      self._at[at],
      "rooms.xml: entity has at=%s but map grid doesn't.",
      at)))
  else
    error("rooms.xml: entity has both x,y and at (or neither)")
  end
end

function tags:customblocker(xml)
  local png = xml.attr.png or xml.attr.pngSprite;
  local x,y = locationFromAttr(self, xml.attr)
  table.insert(self._entities, {
    type = "Wall";
    name = xml.attr.name;
    desc = xml.attr.description;
    x = x; y = y;
    Render = { face = '♦'; png = png };
  })
end

function tags:customengraving(xml)
  local png = xml.attr.png or xml.attr.pngSprite;
  local x,y = locationFromAttr(self, xml.attr)
  table.insert(self._entities, {
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

return tags
