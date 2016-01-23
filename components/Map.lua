-- Component for a map, i.e. a floor of the dungeon or any other space that
-- contains terrain and entities.

local Map = {}

-- Create a new entity owned by this map. It will be automatically registered
-- in the global entity lookup table, but is available only as long as this map
-- is loaded.
function Map:create(init)
  init.id = game.nextID()

  local ent = entity.create(init)
  self.children[ent.id] = ent
  game.register(ent)
  return Ref(ent)
end

function Map:blocked(x, y, type)
  local cell = self.Map[x][y]
  for i=#cell,1,-1 do
    local ent = cell[i]
    if cell[i].blocks and cell[i]:blocks(type) then
      return cell[i]
    end
  end
end

function Map:frobCell(x, y, title, frobber)
  local node = { name = title, expanded = true }
  local cell = self.Map[x][y]
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
  w,h = w or self.Map.w,h or self.Map.h

  return coroutine.wrap(function()
    for x=x,x+w-1 do
      for y=y,y+h-1 do
        coroutine.yield(x, y, self.Map[x][y])
      end
    end
  end)
end

function Map:cell(x, y)
  return self.Map[x][y]
end

function Map:render_screen(cx, cy)
  local w,h = self.Map.w, self.Map.h
  local sw,sh = tty.size() -- screen width and height
  local rw,rh -- render width and height
  local ox,oy -- origin of render region
  local dx,dy -- offset on screen
  -- Map scrolling happens here.
  -- If the map is smaller than the screen, center it.
  -- Otherwise, scroll it to keep (cx,cy) as close to the center of the screen
  -- as possible, without showing black space at the edges.
  if w <= sw then
    rw = w
    ox = 0
    dx = ((sw - w)/2):floor()
  else
    rw = sw
    ox = math.bound(cx - sw/2, 0, w - sw):floor()
    dx = -ox
  end

  if h <= sh then
    rh = h
    oy = 0
    dy = (sh - h)/2
  else
    rh = sh
    oy = math.bound(cy - sh/2, 0, h - sh):floor()
    dy = -oy
  end

  for x,y,cell in self:cells(ox,oy,rw,rh) do
    if #cell > 0 then
      cell[#cell]:render(x+dx, y+dy)
    end
  end
end

function Map:placeAt(object, x, y)
  table.insert(self.Map[x][y], object)
end

function Map:removeFrom(object, x, y)
  local i,objs = 1,self.Map[x][y]
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

return Map
