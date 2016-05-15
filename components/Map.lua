-- Component for a map, i.e. a floor of the dungeon or any other space that
-- contains terrain and entities.

local Map = {}

function Map:msg_init()
  self.Map.positions = {}
  for x=0,self.Map.w-1 do
    self.Map[x] = {}
    for y=0,self.Map.h-1 do
      self.Map[x][y] = {}
    end
  end
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

function Map:contents(x, y)
  local cell = self.Map[x][y]
  local i=#cell+1
  return function()
    i = i - 1
    return cell[i]
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
      -- log.debug('render cell: %d,%d %s', x, y, cell[#cell])
      cell[#cell]:render(x+dx, y+dy)
    end
  end
end

--
-- Entity management
--

-- Create a new entity in the given cell. The map has ownership.
function Map:createAt(x, y, init)
  init.id = init.id or game.nextID()

  local ent = entity.create(init)
  local ref = Ref(ent)
  ent._parent = Ref(self)
  self.children[ent.id] = ent
  game.register(ent)
  self:placeAt(x, y, ref)
  return ref
end

-- Message handler for entity release. Removes the released entity from the
-- map position table.
function Map:msg_release(child)
  local ox,oy = assert(self:positionOf(child))
  if ox then
    self:removeFrom(ox, oy, child)
  end
end

-- Place an existing entity in the given cell. The map takes ownership if it
-- doesn't already have it.
function Map:placeAt(x, y, entity)
  if entity._parent.id ~= self.id then
    self:claim(entity:release())
  end
  -- remove the entity from its old cell
  local ox,oy = self:positionOf(entity)
  if ox then
    self:removeFrom(ox, oy, entity)
  end
  --local ox,oy = unpack(self.Map.positions[entity.id] or {})
  table.insert(self.Map[x][y], entity)
  self.Map.positions[entity.id] = { x, y }
end

function Map:positionOf(entity)
  return unpack(self.Map.positions[entity.id] or {})
end

function Map:removeFrom(x, y, entity)
  local i,cell = 1,self.Map[x][y]
  while i <= #cell do
    if cell[i].id == entity.id then
      table.remove(cell, i)
    else
      i = i+1
    end
  end
  self.Map.positions[entity.id] = nil
end

return Map
