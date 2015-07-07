require 'util'

local tty = {}

function tty.csi(command, ...)
  io.write('\x1B[' .. table.concat({...}, ';') .. command)
end

function tty.put(x, y, text)
  tty.position(x,y)
  io.write(text)
end

function tty.position(x, y)
  -- Swap args because it's in (row, column) order
  return tty.csi('H', y, x)
end

local map = { w=100, h=100 }

for x=1,map.w do
  map[x] = {}
  for y=1,map.h do
    if math.random(1,8) == 8 or x == 1 or x == 100 or y == 1 or y == 100 then
      map[x][y] = '#'
    else
      map[x][y] = '.'
    end
  end
end


local x,y = 10,10

local last_x,last_y = nil,nil
local function render(px, py)
  -- calculate the viewport
  -- we want the player to be as close to the center as possible, without having
  -- empty space at the edges
  -- if map.w <= 80, vpx should always be 0
  -- if it's, say, 100 --
  -- vpx should be 0 if px <= 40
  -- it should be 20 if px >= 60
  -- and it should be px-40 otherwise
  local vpx = math.bound(0, px - 40, map.w-80)
  local vpy = math.bound(0, py - 12, map.h-24)
  for x=1,80 do
    for y=1,24 do
      tty.put(x,y,map[x+vpx][y+vpy])
    end
  end
  tty.put(px-vpx, py-vpy, '@')
  tty.position(px-vpx, py-vpy)
end

os.execute('stty raw -echo')
while true do
  render(x, y)
  local cmd = io.read(1)
  local nx,ny = x,y
  if cmd == 'q' then
    break
  elseif cmd == 'w' then
    ny = y-1
  elseif cmd == 's' then
    ny = y+1
  elseif cmd == 'a' then
    nx = x-1
  elseif cmd == 'd' then
    nx = x+1
  end
  if map[nx] and map[nx][ny] == '.' then
    x,y = nx,ny
  end
end
os.execute('stty cooked echo')
