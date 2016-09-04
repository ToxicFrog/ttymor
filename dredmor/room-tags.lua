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
      self.at[at],
      "rooms.xml: entity has at=%s but map grid doesn't.",
      at)))
  else
    error("rooms.xml: entity has both x,y and at (or neither)")
  end
end

function tags:customblocker(xml)
  local png = xml.attr.png or xml.attr.pngSprite;
  local x,y = locationFromAttr(self, xml.attr)
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
  local x,y = locationFromAttr(self, xml.attr)
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

return tags
