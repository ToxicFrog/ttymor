-- Component for a map, i.e. a floor of the dungeon or any other space that
-- contains terrain and entities.

local map = {}

function map:generate(ent)
  print("generating map")
  self.entities = {}
  for x=1,self.w do
    self[x] = {}
    for y=1,self.h do
      if math.random(1,8) == 8
          or x == 1 or x == self.w
          or y == 1 or y == self.h then
        self[x][y] = '#'
      else
        self[x][y] = '.'
      end
    end
  end
end

function map:try_move(ent, x, y)
  return self[x][y] == '.'
end

function map:render(ent, view, cx, cy)
  -- Map scrolling happens here. It's clamped to between -0 (near edge of map at
  -- edge of screen) and -(map size - view size) (far edge of map at far edge
  -- of screen).
  -- This keeps cx,cy as close to the center of the screen as possible, without
  -- allowing black space at the edge of the screen.
  view.dx = -math.bound(0, cx - view.w/2, self.w - view.w):floor()
  view.dy = -math.bound(0, cy - view.h/2, self.h - view.h):floor()

  for x=1,self.w do
    for y=1,self.h do
      local tile = self[x][y]
      local _x,_y = x + view.dx, y + view.dy
      if view.x < _x and _x <= view.x + view.w
        and view.y < _y and _y <= view.y + view.h
      then
        tty.put(x + view.dx, y + view.dy, tile)
      end
    end
  end

  tty.put(1, 1, view.dx .. "," .. view.dy)

  for id,ent in pairs(self.entities) do
    print(id, ent)
    ent:render(view)
  end
end

function map:add(ent, object)
  self.entities[object.id] = object
end

function map:remove(ent, object)
  self.entities[object.id] = nil
end

return map
