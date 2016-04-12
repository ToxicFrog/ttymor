ui = {}

ui.Window = require 'ui.Window'
ui.Box = require 'ui.Box'
ui.List = require 'ui.List'
ui.Tree = require 'ui.Tree'

function ui.layout()
  local w,h = tty.termsize()
  log.debug('Performing layout calculations: %dx%d', w, h)
  ui.screen:layout(w, h)
end

function ui.init()
  tty.init()

  ui.screen = ui.Window {
    name = "screen";
    position = { -1, -1 };
    size = { inf, inf };
    x = 0; y = 0;
    visible = true;
    render = function(self)
      tty.colour(255, 255, 255, 0, 0, 0)
      tty.style('o')
      tty.clear()
    end;
  }

  -- Log fills the left side of the screen.
  ui.log_win = require 'ui.log_win' {
    position = { -1, -1 };
    size = { 40, inf };
  }
  ui.screen:attach(ui.log_win)

  -- HUD overlays log in the upper left.
  ui.hud_win = require 'ui.hud_win' {
    position = { -1, -1 };
    size = { 40, 0 };
  }
  ui.screen:attach(ui.hud_win)

  -- main view takes up the remaining space
  ui.main_win = require 'ui.main_win' {
    position = { 1, -1 };
    size = { -40, inf };
  }
  ui.screen:attach(ui.main_win)
  ui.layout()
end

function ui.draw()
  if flags.parsed.ui_perf then
    log.debug('-- render begin --')
  end
  ui.screen:renderAll()
  tty.flip()
  if flags.parsed.ui_perf then
    log.debug('-- render end --')
  end
end

function ui.setHUD(title, content)
  if content == nil then
    content = { name = title }
  elseif type(content) == 'string' then
    content = content:wrap(ui.hud_win.w - 4)
  end
  assert(type(content) == 'table', 'invalid argument passed to setHUD')
  content.name = title
  ui.hud_win:setContent(content)
end

function ui.pushHUD()
  ui.hud_win:pushContent()
end

function ui.popHUD()
  ui.hud_win:popContent()
end

-- Draw a box with the upper left corner at (x,y)
function ui.box(rect, title, walls)
  if not rect then
    local w,h = tty.size()
    rect = { x = 0; y = 0; w = w; h = h }
  end

  local w,h = tty.pushwin(rect)

  local default_walls = {
    nw = "┏"; n = "━"; ne = "┓";
    w  = "┃"; c = " "; e =  "┃";
    sw = "┗"; s = "━"; se = "┛";
  }
  default_walls.__index = default_walls
  walls = setmetatable(walls or {}, default_walls)

  tty.put(0, 0, walls.nw..walls.n:rep(w-2)..walls.ne)
  for row=1,h-2 do
    tty.put(0, row, walls.w..walls.c:rep(w-2)..walls.e)
  end
  tty.put(0, h-1, walls.sw..walls.s:rep(w-2)..walls.se)
  if title then
    tty.put(1, 0, '┫'..title:sub(1, w-4)..'┣')
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

function ui.mainmenu()
  ui.tree {
    name = 'Main Menu';
    { name = 'Return to Game';
      help = 'Close the menu and return to the game in progress.';
      activate = function(self) return self.tree:cancel() end; };
    { name = 'Configuration';
      activate = settings.edit;
      help = 'Change game settings and key bindings.' };
    { name = 'Config Debug';
      activate = settings.show;
      help = 'View the raw contents of the settings subsystem, including hidden settings.' };
    { name = 'Room Debug';
      activate = dredmor.debug_rooms;
      help = 'View the raw contents of the room database.' };
    { name = 'Save Game';
      activate = function(self) game.save(); return self.tree:cancel(); end;
      help = 'Save your game in progress.' };
    { name = 'Load Game';
      activate = function(self) game.load(game.name()); return self.tree:cancel(); end;
      help = 'Load your last save.' };
    { name = 'Quit And Save';
      activate = function() game.save(); love.event.quit(); end;
      help = 'Save your game and then quit TTYmor.' };
    { name = 'Quit Without Saving';
      activate = love.event.quit;
      help = 'Immediately quit the same without saving.' };
  }
end

-- Turn a tree into a Tree and activate it, running until one of the handlers
-- returns a value.
function ui.tree(tree)
  ui.pushHUD()
  tree = ui.Tree(tree)
  tree.visible = true
  ui.main_win:attach(tree)
end

function ui.message(title, message)
  if type(message) == 'string' then
    return ui.message(title, {message})
  end
  local w = #title + 4
  for i,line in ipairs(message) do
    w = w:max(#line)
  end

  message.visible = true
  message.x = 1
  message.y = 1
  local list = ui.List(message)
  local box = ui.Box {
    name = title;
    visible = true;
    position = "center";
    w = w + 2;
    h = #message + 2;
    content = list;
  }
  function box:cmd_any()
    self:destroy()
    return true
  end

  ui.main_win:attach(box)
  return box
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
