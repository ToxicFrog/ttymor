love = {
  event = {};
  timer = {};
}

local function main(...)
  love.load {...}
  while true do
    love.draw()
    love.update(0.033)
  end
end

function love.main(...)
  return xpcall(main, love.errhand, ...)
end

function love.event.quit()
  if love.quit() then return end
  os.exit(0)
end

function love.timer.sleep(t)
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

local function readkey()
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

function love.readkey(buffer)
  table.insert(buffer, readkey())
end
