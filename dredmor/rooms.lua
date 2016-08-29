require 'repr'
local Room = require 'dredmor.Room'

-- subtag types
-- row: terrain row
-- flags: room attributes
-- customblocker: blocks movement and maybe LOS
-- custombreakable: as above but can be destroyed by attacks
-- customengraving: custom description, not interactable
-- element: special entities like vendors, statues, etc
-- horde: a swarm of monsters, one is promoted to leader
-- lever: a pullable lever; must be wired to a script to have an effect
-- loot: an item
-- monster: a single monster
-- pedestal: a readable book on a stand
-- trap: a trap; for wall traps specifies trigger location, launcher will be installed automatically

local function insert_row(room, row)
  local y = room.h
  for x=0,#row-1 do
    room[x] = room[x] or {}
    room[x][y] = row:sub(x+1,x+1)
  end
  room.h = room.h + 1
  room.w = room.w:max(#row)
end

local function roomFromXML(node)
  local room = {
    name = node.attr.name;
    contents = {};
    _locations = {};
    _doors = {};
    w = 0; h = 0;
  }
  for tag in xml.walk(node) do
    if tag.name == 'room' then
      -- skip
    elseif tag.name == 'row' then
      -- Width and height are calculated by insert_row, since we can't trust the
      -- values in the <room> tag.
      insert_row(room, tag.attr.text)
    elseif tag.name == 'flags' then
      room.flags = xml.attrs(tag)
    else
      local obj = xml.attrs(tag)
      obj._type = tag.name
      table.insert(room.contents, obj)
    end
  end

  -- The Room constructor is responsible for converting the terrain into something
  -- we can actually work with, building the door list, and suchlike.
  return Room(room)
end

-- Master table of all rooms, indexed by room name.
local rooms = {}

local function loadRooms(path)
  local dom = xml.load(path)
  local count = 0
  for roomdef in xml.walk(dom.root, 'room') do
    if rooms[roomdef.attr.name] then
      log.debug("skipping duplicate room definition %s", roomdef.attr.name)
    else
      count = count+1
      local room = roomFromXML(roomdef)
      rooms[room.name] = room
    end
  end
  log.debug("Loaded %d rooms from %s", count, path)
end

function dredmor.loadRooms()
  return dredmor.loadFiles(loadRooms, '/rooms.xml')
end

function dredmor.rooms(filter)
  local R = {}
  filter = filter or f' => true'
  for _,room in pairs(rooms) do
    if filter(room) then
      R[room.name] = room
      table.insert(R, room)
    end
  end
  log.debug("Returning filtered list of %d rooms", #R)
  return R
end

function dredmor.room(name)
  return rooms[name]
end
