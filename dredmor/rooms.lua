require 'repr'
require 'xml'
local Room = require 'dredmor.Room'

-- Master table of all rooms, indexed by room name.
local rooms = {}

local function loadRooms(path)
  local dom = xml.load(path)
  local count = 0
  for roomdef in xml.walk(dom.root, 'room') do
    if rooms[roomdef.attr.name] then
      log.debug("skipping duplicate room definition %s", roomdef.attr.name)
    else
      local room = Room(roomdef)
      rooms[room.name] = room
      count = count+1
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
