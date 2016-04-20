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
  local tree = { title = 'Room List' }
  for name,room in pairs(rooms) do
    local node = {
      text = room.name;
      _room = room;
    }
    table.insert(tree, node)
    function node:activate(tree)
      local message = { title = self.text }

      local terrain = { text = "TERRAIN"; expanded = true }
      for x,y,cell in self._room:cells() do
        terrain[y] = (terrain[y] or '') .. asChar(cell)
      end
      for y,row in ipairs(terrain) do
        terrain[y] = { text = row }
      end

      local flags = { text = "FLAGS" }
      for k,v in pairs(self._room.flags) do
        table.insert(flags, { text = k..': '..v })
      end

      local doors = { text = "DOORS" }
      for door in self._room:doors() do
        table.insert(doors,
            { text = (repr({x=door.x;y=door.y;dir=door.dir}):gsub('%s+', ' ')) })
      end

      local contents = { text = "CONTENTS" }
      for _,v in ipairs(self._room.contents) do
        table.insert(contents, {text = v._type..': '..(v.name or '???')})
      end

      table.insert(message, terrain)
      table.insert(message, flags)
      table.insert(message, doors)
      table.insert(message, contents)
      ui.tree(message)
    end
  end
  table.sort(tree, function(a,b) return a.text < b.text end)
  ui.tree(tree)
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
