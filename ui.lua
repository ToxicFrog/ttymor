ui = {}

require 'ui.keys'

local last_init,last_hud,last_map,last_log,last_tty,last_frame = 0,0,0,0,0,0
function ui.draw(player)
  game.log("        Log: %.3f TTY: %.3f", last_log, last_tty)
  game.log("        HUD: %.3f Map: %.3f", last_hud, last_map)
  game.log("Render: Ini: %.3f All: %.3f", last_init, last_frame)

  local t = os.clock()

  local w,h = tty.size()
  tty.colour(255, 255, 255, 0, 0, 0)
  tty.style('o')
  tty.clear()
  local x,y,map = player:position()

  -- Calculate viewport offset.
  -- x and y are the offset to add to coordinates before they go to the screen.
  -- w and h are the dimensions of that rectangle.
  local statline_win = {
    x = 0; y = 0;
    w = 16; h = (h/2):floor();
  }
  local hud_win = {
    x = 0; y = statline_win.h;
    w = 16; h = (h/2):ceil();
  }
  local log_win = {
    x = w-40; y = 0;
    w = 40; h = h;
  }
  local map_win = {
    x = hud_win.w+1; y = 0;
    w = w-40-hud_win.w-2; h = h;
  }

  tty.colour(0, 0, 0, 255, 255, 255)
  tty.colour(255, 255, 255, 0, 0, 0)
  ui.vline(map_win.x-1)
  ui.vline(log_win.x-1)
  tty.colour(255, 255, 255, 0, 0, 0)

  last_init = os.clock()

  ui.box(hud_win, "HUD")
  ui.box(statline_win, "stats")

  last_hud = os.clock()

  tty.pushwin(log_win)
  local log = game.getLog()
  for i=1,h do
    local line = (log[#log-i+1] or ""):sub(1, (w/2):floor())
    tty.put(0,i-1,line)
  end
  tty.popwin()

  last_log = os.clock()

  tty.pushwin(map_win)
  game.getMap(map):render_screen(x, y)
  tty.popwin()

  last_map = os.clock()

  tty.flip()

  last_tty = os.clock()
  last_frame = last_tty - t
  last_tty = last_tty - last_map
  last_map = last_map - last_log
  last_log = last_log - last_hud
  last_hud = last_hud - last_init
  last_init = last_init - t
end

-- Draw a box with the upper left corner at (x,y)
function ui.box(rect, title)
  if not rect then
    local w,h = tty.size()
    rect = { x = 0; y = 0; w = w; h = h }
  end

  local w,h = tty.pushwin(rect)

  tty.put(0, 0, "┏"..("━"):rep(w-2).."┓")
  for row=1,h-2 do
    tty.put(0, row, "┃"..(" "):rep(w-2).."┃")
  end
  tty.put(0, h-1, "┗"..("━"):rep(w-2).."┛")
  if title then
    tty.put(1, 0, '┫'..title..'┣')
--    tty.put(1, 0, '╾'..title..'╼')
  end

  tty.popwin()
end

function ui.hline(row)
  local w,h = tty.size()
  tty.put(0, row, ("━"):rep(w))
end

function ui.vline(col)
  local w,h = tty.size()
  for i=1,h do
    tty.put(col, i-1, "┃")
  end
end

function ui.centered(w, h)
  local sw,sh = tty.size()
  return {
    w = w:min(sw); h = h:min(sh);
    x = math.floor((sw-w)/2):max(0);
    y = math.floor((sh-h)/2):max(0);
  }
end

function ui.mainmenu()
  tty.colour(0, 255, 255)
  ui.tree {
    { name="Return to Game"};
    { name='Configuration'; activate = settings.edit; };
    { name="Config Debug"; activate = settings.show };
    { name="Room Debug"; activate = dredmor.debug_rooms };
    { name="Save Game"; activate = function() game.save(); return false; end };
    { name="Load Game"; activate = function() game.load(game.name()); return false; end };
    { name="Quit And Save"; activate = function() game.save(); shutdown(); end };
    { name="Quit Without Saving"; activate = shutdown; };
  }
end

local Tree = require 'ui.Tree'

-- Turn a tree into a Tree and activate it, running until one of the handlers
-- returns a value.
function ui.tree(tree)
  return Tree(tree):run()
end

function ui.message(title, message)
  if type(message) == 'string' then
    return ui.message(title, {message})
  end

  message = table.copy(message)
  message.name = title
  ui.tree(message)
end

function ui.clear(view, char)
  char = char or ' '
  if not view then
    local w,h = tty.size()
    view = { x = 0; y = 0; w = w; h = h }
  end
  tty.pushwin(view)
  for y=0,view.h-1 do
    tty.put(0, y, char:rep(view.w))
  end
  tty.popwin()
end
