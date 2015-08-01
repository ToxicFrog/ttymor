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

function dredmor.load_rooms(path)
  local dom = xml.load(path)
  for roomdef in xml.walk(dom.root, 'room') do
    if rooms[roomdef.attr.name] then
      -- print("skipping duplicate room definition %s" % room.attr.name)
    else
      local room = {
        name = roomdef.attr.name;
        w = roomdef.attr.width;
        h = roomdef.attr.height;
        map = {};
        contents = {};
      }
      for tag in xml.walk(roomdef) do
        if tag.name == 'room' then
          -- skip
        elseif tag.name == 'row' then
          table.insert(room.map, tag.attr.text)
        elseif tag.name == 'flags' then
          room.flags = attrsToTable(tag)
        else
          local obj = attrsToTable(tag)
          obj._type = tag.name
          table.insert(room.contents, obj)
        end
      end
      rooms[room.name] = room
    end
  end
end

function dredmor.debug_rooms()
  dredmor.load_rooms(flags.parsed.dredmor_dir..'/game/rooms.xml')
  dredmor.load_rooms(flags.parsed.dredmor_dir..'/expansion/game/rooms.xml')
  dredmor.load_rooms(flags.parsed.dredmor_dir..'/expansion2/game/rooms.xml')
  --dredmor.load_rooms(flags.parsed.dredmor_dir..'/expansion3/game/rooms.xml') Wizardlands doesn't have one.
  local tree = { name = 'Room List' }
  for name,room in pairs(rooms) do
    table.insert(tree, room)
    function room:activate()
      local message = table.copy(self.map)
      table.insert(message, "--- flags ---")
      for k,v in pairs(self.flags) do
        table.insert(message, k..': '..v)
      end
      table.insert(message, "--- contents ---")
      for _,v in ipairs(self.contents) do
        table.insert(message, v._type..': '..(v.name or '???'))
      end

      ui.message(self.name, message)
    end
  end
  table.sort(tree, function(a,b) return a.name < b.name end)
  ui.tree(tree)
end

function dredmor.rooms()
  return rooms
end
