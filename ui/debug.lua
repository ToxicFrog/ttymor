-- Debug submenu for the main menu, and useful debugging functions.

local function tileAsChar(tile)
  if not tile then return ' '
  elseif tile == 'Wall' then return '#'
  elseif tile == 'Floor' then return '.'
  else return tile:sub(1,1)
  end
end

local function debugRooms()
  local rooms = dredmor.rooms()
  local tree = { title = 'Room Database' }
  for name,room in pairs(rooms) do
    local node = {
      text = room.name;
      _room = room;
    }
    table.insert(tree, node)
    function node:cmd_activate()
      local message = { title = self.text }

      local terrain = { text = "TERRAIN"; expanded = true; }
      for x,y,cell in self._room:cells() do
        terrain[y] = (terrain[y] or '') .. tileAsChar(cell)
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
      return true
    end
  end
  table.sort(tree, function(a,b) return a.text < b.text end)
  ui.tree(tree)
  return true
end

local function giveItems()
  player = game.get 'player'
  for i=1,100 do
    local name = dredmor.randomItem()
    player:getItem(player:createChild { type = name })
  end
  return true
end

return {
  text = 'Debug';
  help = 'Debugging commands';
  { text = 'Give Items';
    cmd_activate = giveItems;
    help = 'Give the player 100 randomly selected items' };
  { text = 'Config Database';
    cmd_activate = function() settings.show(); return true; end;
    help = 'View the raw contents of the settings subsystem, including hidden settings.' };
  { text = 'Room Database';
    cmd_activate = debugRooms;
    help = 'View the raw contents of the room database.' };
  { text = 'Item Database';
    -- not implemented yet
    help = 'View the contents of the Dredmor item database' };
  { text = 'Entity Definitions';
    -- not implemented yet
    help = 'View all registered entity types and their definitions' };
}
