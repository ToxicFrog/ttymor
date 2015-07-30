local Map = {}
Map.__index = Map

local function new(game, depth)
  return setmetatable({
    w = -1;
    h = -1;
    game = game;
    depth = depth;
    entities = {};
  }, Map)
end

function Map:createEntity(type)
  return function(initializer)
    local ent = Entity(type)(initializer)
    self.entities[id] = ent
    game.ref(ent)
    return game.get(ent)
  end
end

function Map:generate(w, h)
  assert(self.w < 0 and self.h < 0, "attempt to regenerate an already-generated map")
  assert(w > 0 and h > 0, "map dimensions must be positive")
  self.w = w
  self.h = h
  local wall = self.game:Singleton 'Wall'
  local floor = self.game:Singleton 'Floor'

  for x=1,self.w do
    self[x] = {}
    for y=1,self.h do
      if math.random(1,8) == 8
          or x == 1 or x == self.w
          or y == 1 or y == self.h then
        self[x][y] = { wall }
      else
        self[x][y] = { floor }
      end
    end
  end
end

function Map:try_move(x, y)
  return self[x][y][1].name == "floor"
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

  game.log("draw: %d,%d+%d+%d (%dx%d)", ox, oy, rw, rh, sw, sh)
  for x=ox,ox+rw-1 do
    for y=oy,oy+rh-1 do
      assert(x >= 0 and x < self.w, "x out of bounds: "..x)
      assert(y >= 0 and y < self.h, "y out of bounds: "..y)

      local cell = self[x+1][y+1]
      if #cell > 0 then
        cell[#cell]:render(x+dx, y+dy)
      end
    end
  end
end

function Map:placeAt(object, x, y)
  --game.log("%s:placeAt(%s, %d, %d)", ent, object, x, y)
  table.insert(self[x][y], object)
end

function Map:removeFrom(object, x, y)
  --game.log("%s:removeFrom(%s, %d, %d)", ent, object, x, y)
  local i,objs = 1,self[x][y]
  while i <= #objs do
    if objs[i].id == object.id then
      table.remove(objs, i)
    else
      i = i+1
    end
  end
end

return new
