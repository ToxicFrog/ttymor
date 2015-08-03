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

local function attrsToTable(tag)
  local T = {}
  for _,attr in ipairs(tag.attr) do
    T[attr.name] = attr.value
  end
  return T
end

local function insert_row(map, row)
  local y = map[1] and #map[1]+1 or 1
  for x=1,#row do
    map[x] = map[x] or {}
    map[x][y] = row:sub(x,x)
  end
end

local function roomFromXML(node)
  local room = {
    name = node.attr.name;
    contents = {};
    _locations = {};
    _doors = {};
  }
  for tag in xml.walk(node) do
    if tag.name == 'room' then
      -- skip
    elseif tag.name == 'row' then
      insert_row(room, tag.attr.text)
    elseif tag.name == 'flags' then
      room.flags = attrsToTable(tag)
    else
      local obj = attrsToTable(tag)
      obj._type = tag.name
      table.insert(room.contents, obj)
    end
  end

  -- A bunch of rooms in the expansion2 rooms.xml have the wrong width/height
  -- values in the <room> tag.
  -- This doesn't seem to bother Dredmor itself. Presumably it ignores the values
  -- in the tag and calculates w/h from the <row> elements. We do the same here.
  room.w = #room
  room.h = #room[1]

  -- The Room constructor is responsible for converting the terrain into something
  -- we can actually work with, building the door list, and suchlike.
  return Room(room)
end

-- Master table of all rooms, which is both a list and indexed by room name.
local rooms = {}
-- Master table of all doors, grouped by facing direction.
local doors = { n={}; s={}; e={}; w={}; }

local function loadRooms(path)
  local dom = xml.load(path)
  for roomdef in xml.walk(dom.root, 'room') do
    if rooms[roomdef.attr.name] then
      -- print("skipping duplicate room definition %s" % room.attr.name)
    else
      local room = roomFromXML(roomdef)
      rooms[room.name] = room
      table.insert(rooms, room)
      for door in room:doors() do
        table.insert(doors[door.dir], door)
      end
    end
  end
end

function dredmor.loadRooms()
  loadRooms(flags.parsed.dredmor_dir..'/game/rooms.xml')
  loadRooms(flags.parsed.dredmor_dir..'/expansion/game/rooms.xml')
  loadRooms(flags.parsed.dredmor_dir..'/expansion2/game/rooms.xml')
  -- No entry for expansion3 because Wizardlands doesn't come with a rooms.xml
  -- Instead it has a special file for "wizardlands rooms" which is not yet loaded.
end

local function asChar(tile)
  if not tile then return ' '
  elseif tile == 'Wall' then return '#'
  elseif tile == 'Floor' then return '.'
  else return tile:sub(1,1)
  end
end

function dredmor.debug_rooms()
  local tree = { name = 'Room List' }
  for i,room in ipairs(rooms) do
    local node = {
      name = room.name;
      _room = room;
    }
    table.insert(tree, node)
    function node:activate()
      local message = {}

      local terrain = { name = "TERRAIN"; expanded = true }
      for x,y,cell in self._room:cells() do
        terrain[y] = (terrain[y] or '') .. asChar(cell)
      end

      local flags = { name = "FLAGS" }
      for k,v in pairs(self._room.flags) do
        table.insert(flags, k..': '..v)
      end

      local doors = { name = "DOORS" }
      for door in self._room:doors() do
        table.insert(doors, (repr({x=door.x;y=door.y;dir=door.dir}):gsub('%s+', ' ')))
      end

      local contents = { name = "CONTENTS" }
      for _,v in ipairs(self._room.contents) do
        table.insert(contents, v._type..': '..(v.name or '???'))
      end

      table.insert(message, terrain)
      table.insert(message, flags)
      table.insert(message, doors)
      table.insert(message, contents)
      ui.message(self.name, message)
    end
  end
  table.sort(tree, function(a,b) return a.name < b.name end)
  ui.tree(tree)
end

function dredmor.rooms()
  return rooms
end

function dredmor.randomRoom()
  return rooms[math.random(1, #rooms)]
end

function dredmor.randomDoor(dir)
  local doors = doors[dir]
  return doors[math.random(1, #doors)]
end
