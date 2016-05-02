tty = {}

flags.register "debug-rendering-stack" {
  help = "Log each window as it's pushed or popped";
}

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
  local w,h = tty.termsize()
  stack[1] = {
    x = 0, y = 0;   -- Offset of the drawing region. All drawing commands are relative to this.
    w = w, h = h;   -- Width and height of the drawing region.
    cx = 0, cy = 0; -- Offset of the clipping rectangle.
    cw = w, ch = h; -- Width and height of the clipping rectangle.
    colour = { 255, 255, 255 };
    style = 'o';
  }
  stack[1].__index = stack[1]
  top = stack[1]
  tty.csi('h', '?', 47) -- DECSET alternate screen buffer
  tty.csi('l', '?', 25) -- DECRST cursor
  tty.flip()
  log.info('TTY initialized: %dx%d', w, h)
  return w,h
end

function tty.deinit()
  buf = {}
  tty.csi('l', '?', 47) -- DECRST alternate screen buffer
  tty.csi('h', '?', 25) -- DECSET cursor
  tty.flip()
  os.execute('stty cooked echo')
  log.info('TTY deinitialized')
end

-- return size of terminal
function tty.termsize()
  local data = io.popen('stty -a'):read('*a')
  local w = data:match('columns (%d+)'):tonumber()
  local h = data:match('rows (%d+)'):tonumber()
  return w,h
end

-- return dimensions of top of rendering stack, i.e. size of clipping region
function tty.size()
  return top.cw,top.ch
end

function tty.bounds()
  return top
end

function tty.flip()
  io.write(table.concat(buf, ""))
  buf = {}
end

-- Check if the given (absolute) coordinates are inside the current clipping region.
local function in_bounds(x, y)
  return top.cx <= x and x < (top.cx + top.cw)
     and top.cy <= y and y < (top.cy + top.ch)
end

local function absolute(x, y)
  return x + top.x, y + top.y
end

-- Push a new drawing region onto the stack.
-- We first translate the window into absolute coordinates; then we compute the
-- new clipping region by intersecting the new window with the old clipping
-- region, and store that as part of the pushed window.
-- The drawing region can also contain colour and style keys, which will be
-- applied when it is pushed and restored to the old values when it is popped.
-- Any parameters not specified will be inherited from the top.
function tty.push(win)
  -- Create the new window with x,y translated into absolute coordinates.
  local new_top = setmetatable({
    name = getmetafield(win, '__tostring') and tostring(win) or win.name or tostring(win);
    x = win.x + top.x; y = win.y + top.y;
    w = win.w, h = win.h;
    colour = win.colour;
    style = win.style;
  }, top)
  new_top.__index = new_top

  if flags.parsed.debug_rendering_stack then
    indent = (" "):rep(#stack-1)
    log.debug("tty.push:%s%s (%d,%d) %dx%d", indent, new_top.name, new_top.x, new_top.y, new_top.w, new_top.h)
  end

  -- Calculate the new clipping region.
  new_top.cx = new_top.x:bound(top.cx, top.cx + top.cw)
  new_top.cy = new_top.y:bound(top.cy, top.cy + top.ch) -- 34
  new_top.cw = (new_top.x + new_top.w):bound(top.cx, top.cx + top.cw) - new_top.cx
  new_top.ch = (new_top.y + new_top.h):bound(top.cy, top.cy + top.ch) - new_top.cy

  -- Apply new colour/style settings.
  tty.colour(unpack(new_top.colour))
  tty.style(new_top.style)

  table.insert(stack, new_top)
  top = stack[#stack]
  return tty.size()
end

function tty.pop()
  assert(#stack > 1, "tty window stack underflow")
  local win = table.remove(stack)
  local new_top = stack[#stack]
  tty.colour(unpack(new_top.colour))
  tty.style(new_top.style)

  if flags.parsed.debug_rendering_stack then
    indent = (" "):rep(#stack-1)
    log.debug("tty.pop:%s%s", indent, top.name)
  end

  top = new_top
  return tty.size()
end

function tty.clear()
  tty.csi('J', 2)
end

function tty.csi(command, ...)
  buf[#buf+1] = '\x1B[' .. table.concat({...}, ';') .. command
end

function tty.put(x, y, text)
  -- Convert to absolute coordinates.
  x,y = absolute(x,y)
  -- Silently drop draws outside the clipping region.
  if not in_bounds(x, y) then return end
  assertf(type(text) == 'string', 'Invalid input to tty.put(): %s', text)
  tty.move(x,y)
  buf[#buf+1] = text
end

-- Position the cursor at the given ABSOLUTE coordinates.
-- Takes (0,0) coordinates, converts to screen (1,1).
function tty.move(x, y)
  -- Check that the new cursor position is within the bounds of the current
  -- clipping region. tty.put() should ensure that this check is never violated.
  assertf(in_bounds(x, y), "out of bounds draw: %d,%d", x, y)
  -- We add 1 to each since the TTY wants (1,1) based coordinates.
  x,y = x+1,y+1
  -- Skip if this is where the cursor is already, so we don't emit lots of
  -- duplicate drawing commands.
  if x == X and y == Y then return end
  X,Y = x,y
  -- And since the TTY wants (row,col) rather than (x,y), we flip the arguments.
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
local STYLE = nil

function tty.style(chars)
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
  local style = table.concat(codes, ';')
  if style ~= STYLE then
    tty.csi('m', style)
    STYLE = style
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
