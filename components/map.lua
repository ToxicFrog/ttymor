-- Component for a map, i.e. a floor of the dungeon or any other space that
-- contains terrain and entities.

local map = {}

function map:generate(ent)
  local wall = game.add {
    name = "wall";
    Component 'render' { face = '#' };
  }
  local floor = game.add {
    name = "floor";
    Component 'render' { face = '.' };
  }
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

function map:try_move(ent, x, y)
  return self[x][y][1].name == "floor"
end

function map:render_screen(ent, view, cx, cy)
  -- Map scrolling happens here. It's clamped to between -0 (near edge of map at
  -- edge of screen) and -(map size - view size) (far edge of map at far edge
  -- of screen).
  -- This keeps cx,cy as close to the center of the screen as possible, without
  -- allowing black space at the edge of the screen.
  view.dx = -math.bound(0, cx - view.w/2, self.w - view.w):floor()
  view.dy = -math.bound(0, cy - view.h/2, self.h - view.h):floor()

  for x=1,self.w do
    for y=1,self.h do
      local _x,_y = x + view.dx, y + view.dy
      if view.x < _x and _x <= view.x + view.w
        and view.y < _y and _y <= view.y + view.h
      then
        local cell = self[x][y]
        if #cell > 0 then
          tty.put(x + view.dx, y + view.dy, cell[#cell]:render())
        end
      end
    end
  end
end

function map:placeAt(ent, object, x, y)
  table.insert(self[x][y], object)
end

function map:removeFrom(ent, object, x, y)
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

return map
