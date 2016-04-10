tty = {}

-- Stack of rendering states.
local stack = {}
local top = nil

-- Buffer for current frame.
local buf = {}

-- position of cursor
local X,Y = 0,0

-- Initialize the tty.
function tty.init()
  os.execute('stty raw isig -echo')
  local data = io.popen('stty -a'):read('*a')
  local w = data:match('columns (%d+)'):tonumber()
  local h = data:match('rows (%d+)'):tonumber()
  stack[1] = { x=0, y=0, w=w, h=h }
  top = stack[1]
  tty.csi('h', '?', 47) -- DECSET alternate screen buffer
  tty.csi('l', '?', 25) -- DECRST cursor
  tty.flip()
  return tty.size()
end

function tty.deinit()
  tty.csi('l', '?', 47) -- DECRST alternate screen buffer
  tty.csi('h', '?', 25) -- DECSET cursor
  tty.flip()
  os.execute('stty cooked echo')
end

function tty.size()
  return top.w,top.h
end

function tty.bounds()
  return top
end

function tty.flip()
  io.write(table.concat(buf, ""))
  buf = {}
end

local function in_bounds(x, y)
  return 0 <= x and x <= top.w
    and 0 <= y and y <= top.h
end

-- Push a new drawing region onto the stack.
function tty.pushwin(x, y, w, h)
  if type(x) == 'table' then
    return tty.pushwin(x.x, x.y, x.w, x.h)
  end

  -- Check that the window is fully in bounds.
  assertf(x and y and w and y, "incomplete window in tty.pushwin()")
  assertf(in_bounds(x, y), "window position out of bounds: %d,%d", x, y)
  assertf(in_bounds(x + w, y + h), "window size out of bounds: %d,%d+%dx%d > %dx%d",
      x, y, w, h, top.w, top.h)
  x = x + top.x
  y = y + top.y
  table.insert(stack, { x = x, y = y; w = w, h = h; })
  top = stack[#stack]
  return tty.size()
end

function tty.popwin()
  assert(#stack > 1, "tty window stack underflow")
  local win = table.remove(stack)
  top = stack[#stack]
  return tty.size()
end

function tty.clear()
  tty.csi('J', 2)
end

function tty.csi(command, ...)
  buf[#buf+1] = '\x1B[' .. table.concat({...}, ';') .. command
end

function tty.put(x, y, text)
  tty.move(x,y)
  buf[#buf+1] = text
end

function tty.move(x, y)
  if x == X and y == Y then return end
  -- Check that the new cursor position is within the bounds of the current drawing
  -- window. A check in tty.pushwin() ensures that the window itself is valid.
  assertf(in_bounds(x, y), "out of bounds draw: %d,%d", x, y)
  -- This is where the transformation from logical to screen coordinates happens.
  -- The TTY uses a (1,1) origin, so we add 1 to both values after applying the
  -- CTM, and the H command is in (row,column) order, so we flip the arguments.
  X,Y = x+top.x+1,y+top.y+1
  tty.csi('H', Y, X)
end

local FG,BG = nil,nil

function tty.colour(r,g,b, br,bg,bb)
  local fg = r..';'..g..';'..b
  if FG ~= fg then
    tty.csi('m', 38, 2, r, g, b)
    FG = fg
  end
  if br then
    tty.bgcolour(br,bg,bb)
  end
end

function tty.bgcolour(r,g,b)
  local bg = r..';'..g..';'..b
  if BG ~= bg then
    tty.csi('m', 48, 2, r, g, b)
    BG = bg
  end
end

local styles = {
  o = 0; b = 1;  i = 3;  u = 4;  v = 7;  s = 9;
  O = 0; B = 22; I = 23; U = 24; V = 27; S = 29;
}
local STYLE = {}

function tty.style(chars)
  if STYLE == chars then return end
  chars = chars or ''
  local codes = {}
  for char in chars:gmatch('.') do
    if styles[char] then
      table.insert(codes, styles[char])
    end
    if char == 'o' or char == 'O' then
      FG,BG = nil,nil
    end
  end
  if #codes > 0 then
    tty.csi('m', unpack(codes))
  end
end

local keynames = {
  [' '] = 'space';
  ['\x1B[A'] = 'up';
  ['\x1B[B'] = 'down';
  ['\x1B[C'] = 'right';
  ['\x1B[D'] = 'left';
  ['\x1B[H'] = 'home';
  ['\x1B[F'] = 'end';
  ['\x1B[5~'] = 'pgup';
  ['\x1B[6~'] = 'pgdn';
  ['\x1B\x1B'] = 'esc';
  ['\x1B[2~'] = 'ins';
  ['\x7F'] = 'del';
}

for char in ('ABCDEFGHIJKLMNOPQRSTUVWXYZ'):gmatch('.') do
  keynames[char:lower()] = char
  keynames[char] = "s-"..char
  keynames['\x1B'..char:lower()] = "m-"..char
  keynames['\x1B'..char] = "m-s-"..char
  keynames[string.char(char:byte() - 0x40)] = "c-"..char
end

keynames['\t'] = 'tab'
keynames['\n'] = 'enter'
keynames['\r'] = 'enter'

local function keyname(k) return keynames[k] or k end

function tty.readkey()
  -- read a single keystroke from the terminal. One keystroke may be multiple characters!
  -- keys are either:
  -- CSI <digits> ~  (special keys)
  -- CSI <letter>    (arrow keys and others)
  -- ESC <uppercase>    (meta-shift-*)
  -- ESC <lowercase>    (meta-*)
  -- ESC ESC            ('escape' pressed twice)
  -- a single character in the range \x01-\x1A (ctrl-letter)
  -- a single printable character
  local key = io.read(1)
  if key ~= '\x1B' then return keyname(key) end

  key = key..io.read(1)
  if keynames[key] then return keyname(key) end

  local digit = io.read(1)
  if not digit:match('%d') then
    return keyname(key..digit)
  else
    key = key..digit
    repeat
      key = key..io.read(1)
    until key:match('~$')
    return keyname(key)
  end
end
