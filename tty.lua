tty = {}

local ctm = { x=0, y=0 }
local buf = ""

function tty.flip()
  io.write(buf)
  buf = ""
end

function tty.csi(command, ...)
  buf = buf .. '\x1B[' .. table.concat({...}, ';') .. command
end

function tty.put(x, y, text)
  tty.move(x+ctm.x,y+ctm.y)
  buf = buf .. text
end

function tty.ctm(x, y)
  ctm.x,ctm.y = x,y
end

function tty.move(x, y)
  -- Swap args because it's in (row, column) order
  return tty.csi('H', y, x)
end

function tty.clear()
  tty.csi('J', 2)
end

-- Initialize the tty. Returns the tty width and height.
function tty.init()
  os.execute('stty raw isig -echo')
  return tty.size()
end

function tty.deinit()
  os.execute('stty cooked echo')
end

function tty.size()
  local data = io.popen('stty -a'):read('*a')
  local w = data:match('columns (%d+)'):tonumber()
  local h = data:match('rows (%d+)'):tonumber()
  return w,h
end
