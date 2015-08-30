-- Component for a map, i.e. a floor of the dungeon or any other space that
-- contains terrain and entities.

local Map = {}
Map.__index = Map

function Map:__tostring()
  return "Map:%s(%s)" % { self.depth, self.name }
end

local function new(data)
  data.entities = {}
  return setmetatable(data, Map)
end

function Map:save()
  return game.saveObject("%d.map" % self.depth, self, true)
end

function Map:load()
  table.merge(self, game.loadObject("%d.map" % self.depth, true), overwrite)
  for id,ent in pairs(self.entities) do
    game.register(ent)
  end
end

-- Create a new entity owned by this map. It will be automatically registered
-- in the global entity lookup table, but is available only as long as this map
-- is loaded.
local Entity = require 'game.Entity'
function Map:create(type)
  return function(data)
    data.id = game.nextID()

    local ent = Entity(type)(data)
    self.entities[data.id] = ent
    game.register(ent)
    return Ref(ent)
  end
end

-- Map generation is large enough that it gets its own library.
Map.generate = require 'game.mapgen'

function Map:blocked(x, y, type)
  local cell = self[x][y]
  for i=#cell,1,-1 do
    local ent = cell[i]
    if cell[i].blocks and cell[i]:blocks(type) then
      return cell[i]
    end
  end
end

function Map:frob(x, y, title, frobber)
  local node = { name = title, expanded = true }
  local cell = self[x][y]
  for i=#cell,1,-1 do
    table.insert(node, cell[i]:frob(frobber) or nil)
  end
  if #node > 0 then
    return node
  end
end

-- Return an iterator over map cells in the given rectangle
function Map:cells(x, y, w, h)
  x,y = x or 0,y or 0
  w,h = w or self.w,h or self.h

  return coroutine.wrap(function()
    for x=x,x+w-1 do
      for y=y,y+h-1 do
        coroutine.yield(x, y, self[x][y])
      end
    end
  end)
end

function Map:cell(x, y)
  return self[x][y]
end

function Map:render_screen(cx, cy)
  local sw,sh = tty.size() -- screen width and height
  local rw,rh -- render width and height
  local ox,oy -- origin of render region
  local dx,dy -- offset on screen

  -- Map scrolling happens here.
  -- If the map is smaller than the screen, center it.
  -- Otherwise, scroll it to keep (cx,cy) as close to the center of the screen
  -- as possible, without showing black space at the edges.
  if self.w <= sw then
    rw = self.w
    ox = 0
    dx = ((sw - self.w)/2):floor()
  else
    rw = sw
    ox = math.bound(0, cx - sw/2, self.w - sw):floor()
    dx = -ox
  end

  if self.h <= sh then
    rh = self.h
    oy = 0
    dy = (sh - self.h)/2
  else
    rh = sh
    oy = math.bound(0, cy - sh/2, self.h - sh):floor()
    dy = -oy
  end

  for x,y,cell in self:cells(ox,oy,rw,rh) do
    if #cell > 0 then
      cell[#cell]:render(x+dx, y+dy)
    end
  end
end

function Map:placeAt(object, x, y)
  table.insert(self[x][y], object)
end

function Map:removeFrom(object, x, y)
  local i,objs = 1,self[x][y]
  local removals = 0
  while i <= #objs do
    if objs[i].id == object.id then
      table.remove(objs, i)
      removals = removals+1
    else
      i = i+1
    end
  end
end

return new
