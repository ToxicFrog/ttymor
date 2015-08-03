require 'repr'

local rooms = {}

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

-- doors
-- ╸ ╺ open
-- ╼━╾ closed
-- ╹ ╽
--   ┃
-- ╻ ╿


-- table mapping terrain chars to cell contents
-- each one is either a table, in which case the 0 key is the EntityType of the
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

  S = { 'Floor'; 'Shopkeeper' };
  i = { 'Wall', 'ShopPedestal' };
  s = function(room, x, y)
    room.shop_door = {x,y}
    room.map[x][y] = 'Floor'
  end;
  -- north-south door
  D = function(room, x, y)
    local map = room.map
    table.insert(room.doors, {
      x = x-1;
      y = y-1;
      dir = y == 1 and "n" or "s";
    })
    map[x-1][y],map[x][y],map[x+1][y] = false,false,false
  end;
  -- east-west door
  d = function(room, x, y)
    local map = room.map
    table.insert(room.doors, {
      x = x-1;
      y = y-1;
      dir = x == 1 and "w" or "e";
    })
    map[x][y-1],map[x][y],map[x][y+1] = false,false,false
  end;
}

local function bad_tile(icon)
  return function(map)
    return { game.createSingleton('Floor', 'error:'..icon) {
      render = { face = icon; style = 'v'; colour = { 255, 0, 0 }}
    }}
  end
end

local function insert_row(map, row)
  local y = map[1] and #map[1]+1 or 1
  for x=1,#row do
    map[x] = map[x] or {}
    map[x][y] = row:sub(x,x)
  end
end

-- Room postprocessor. There's a bunch of things that have to happen here, eventually,
-- but for now the most important ones are this:
-- - beacons (1-9) need to be located, replaced with '.', and entered into the location array
-- - doors need to be located, their direction determined, and entered into the doors array
-- - terrain needs to be replaced with the EntityType of the corresponding terrain
-- - everything else needs to be added to the room.contents array and replaced with terrain
local function postprocess(room)
  local map = room.map
  for x=1,room.w do
    for y=1,room.h do
      local cell = map[x][y] or ' ' -- not all rooms are perfect rectangles!
      if cell:match('%d') then -- location marker
        room.locations[tonumber(cell)] = { x=x-1, y=y-1 }
        map[x][y] = 'Floor'
      elseif terrain[cell] then
        local content = terrain[cell]
        if type(content) == 'table' then
          map[x][y] = content[1]
          for i=2,#content do
            table.insert(room.contents, {_type = "Terrain"; name=content[i]})
          end
        else
          content(room, x, y)
        end
      else
        errorf('Unhandled terrain cell type "%s" reading room %s"',
          cell, room.name)
      end
    end
  end
end

local function roomFromXML(node)
  local room = {
    name = node.attr.name;
    map = {};
    contents = {};
    locations = {};
    doors = {};
  }
  for tag in xml.walk(node) do
    if tag.name == 'room' then
      -- skip
    elseif tag.name == 'row' then
      insert_row(room.map, tag.attr.text)
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
  room.w = #room.map
  room.h = #room.map[1]
  postprocess(room)

  return room
end

local function loadRooms(path)
  local dom = xml.load(path)
  for roomdef in xml.walk(dom.root, 'room') do
    if rooms[roomdef.attr.name] then
      -- print("skipping duplicate room definition %s" % room.attr.name)
    else
      local room = roomFromXML(roomdef)
      rooms[room.name] = room
      table.insert(rooms, room)
    end
  end
end

function dredmor.loadRooms()
  loadRooms(flags.parsed.dredmor_dir..'/game/rooms.xml')
  loadRooms(flags.parsed.dredmor_dir..'/expansion/game/rooms.xml')
  loadRooms(flags.parsed.dredmor_dir..'/expansion2/game/rooms.xml')
  --loadRooms(flags.parsed.dredmor_dir..'/expansion3/game/rooms.xml') Wizardlands doesn't have one.
end

function dredmor.debug_rooms()
  local tree = { name = 'Room List' }
  for i,room in ipairs(rooms) do
    table.insert(tree, room)
    function room:activate()
      local message = {}

      local terrain = { name = "TERRAIN"; expanded = true }
      for y=1,room.h do
        local row = ''
        for x=1,room.w do
          row = row..room.map[x][y]
        end
        table.insert(terrain, row)
      end

      local flags = { name = "FLAGS" }
      for k,v in pairs(self.flags) do
        table.insert(flags, k..': '..v)
      end

      local contents = { name = "CONTENTS" }
      for _,v in ipairs(self.contents) do
        table.insert(contents, v._type..': '..(v.name or '???'))
      end

      local raw = { name = "REPR" }
      for line in repr(self.map):gmatch('[^\n]+') do
        table.insert(raw, line)
      end

      table.insert(message, terrain)
      table.insert(message, flags)
      table.insert(message, contents)
      table.insert(message, raw)
      ui.message(self.name, message)
    end
  end
  table.sort(tree, function(a,b) return a.name < b.name end)
  ui.tree(tree)
end

function dredmor.rooms()
  return rooms
end
