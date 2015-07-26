local rooms = {}

local repr = require 'repr'
function dredmor.load_rooms(path)
  local dom = xml.load(path)
  for room in xml.walk(dom.root, 'room') do
    if rooms[room.attr.name] then
      -- print("skipping duplicate room definition %s" % room.attr.name)
    else
      local map = {}
      rooms[room.attr.name] = {
        name = room.attr.name;
        w = room.attr.width;
        h = room.attr.height;
        map = map;
      }
      for row in xml.walk(room, 'row') do
        table.insert(map, row.attr.text)
      end
    end
  end
end

function dredmor.debug_rooms()
  dredmor.load_rooms(flags.parsed.dredmor_dir..'/game/rooms.xml')
  local tree = { name = 'Room List' }
  for name,room in pairs(rooms) do
    table.insert(tree, room)
    function room:activate()
      ui.message(self.name, self.map)
    end
  end
  table.sort(tree, function(a,b) return a.name < b.name end)
  ui.tree(tree)
end

function dredmor.rooms()
  return rooms
end
