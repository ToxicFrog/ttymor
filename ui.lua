ui = {}

ui.Window = require 'ui.Window'
ui.Box = require 'ui.Box'
ui.Tree = require 'ui.Tree'
ui.VList = require 'ui.VList'
ui.TextLine = require 'ui.TextLine'
ui.EntityLine = require 'ui.EntityLine'
ui.Expander = require 'ui.Expander'
ui.Stack = require 'ui.Stack'
ui.Inventory = require 'ui.Inventory'
ui.WrappingTextLine = require 'ui.WrappingTextLine'

function ui.layout()
  local w,h = tty.termsize()
  log.debug('Performing layout calculations: %dx%d', w, h)
  ui.screen:layout { w=w, h=h }
end

function ui.init()
  tty.init()

  ui.screen = ui.Window {
    name = "screen";
    position = { 0, 0 };
    size = { inf, inf };
    x = 0; y = 0;
    render = function(self)
      tty.colour(255, 255, 255, 0, 0, 0)
      tty.style('o')
      tty.clear()
    end;
  }
  function ui.screen:cmd_exit_game()
    love.event.quit()
  end

  -- Log fills the left side of the screen.
  ui.log_win = require 'ui.log_win' {
    position = { 0, 0 };
    size = { 40, inf };
  }
  ui.screen:attach(ui.log_win)

  -- HUD overlays log in the upper left.
  ui.hud_win = require 'ui.hud_win' {
    position = { 0, 0 };
    size = { 40, 0 };
  }
  ui.screen:attach(ui.hud_win)

  -- main view takes up the remaining space
  ui.main_win = ui.Stack {
    name = 'main stack';
    position = { 1, 0 };
    size = { -40, inf };
  }
  ui.main_win:attach(require 'ui.main_win' {
    position = { 0, 0 };
    size = { inf, inf };
  })
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

-- Set the HUD title and contents. 'content' should be a table of ui elements,
-- which will become the contents of the HUD's internal VList; if passed a string,
-- it will automatically be turned into a WrappingTextLine.
function ui.setHUD(title, content)
  if type(content) == 'string' then
    local ww = ui.hud_win:getChildBB().w
    content = {
      ui.WrappingTextLine { text = content, wrap_width = ww };
    }
  end
  assert(type(content) == 'table', 'invalid argument passed to setHUD: '..repr(content))
  ui.hud_win:setContent(title, content)
end

-- Draw a box with the upper left corner at (x,y)
function ui.box(rect, title, walls)
  if not rect then
    local w,h = tty.size()
    rect = { x = 0; y = 0; w = w; h = h; name = "anonymous box"; }
  end

  local w,h = tty.push(rect)

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
--    tty.put(1, 0, '┫'..title:sub(1, w-4)..'┣')
    tty.put(1, 0, '╾'..title..'╼')
  end

  tty.pop()
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
    title = 'Main Menu';
    { text = 'Return to Game';
      help = 'Close the menu and return to the game in progress.';
      cmd_activate = function() ui.sendEvent(nil, 'cancel'); return true; end; };
    { text = 'Configuration';
      cmd_activate = function() settings.edit(); return true; end;
      help = 'Change game settings and key bindings.' };
    table.copy(require 'ui.debug');
    { text = 'Save Game';
      cmd_activate = function() game.save(); ui.sendEvent(nil, 'cancel'); return true; end;
      help = 'Save your game in progress.' };
    { text = 'Load Game';
      cmd_activate = function() game.load(game.name()); ui.sendEvent(nil, 'cancel'); return true; end;
      help = 'Load your last save.' };
    { text = 'Quit And Save';
      cmd_activate = function() game.save(); love.event.quit(); end;
      help = 'Save your game and then quit TTYmor.' };
    { text = 'Quit Without Saving';
      cmd_activate = love.event.quit;
      help = 'Immediately quit the same without saving.' };
  }
end

-- Turn a tree into a Tree and activate it, running until one of the handlers
-- returns a value.
function ui.tree(tree)
  tree = ui.Tree(tree)
  ui.main_win:attach(tree)
  ui.main_win:layout()
  return tree
end

function ui.message(title, message)
  if type(message) == 'string' then
    return ui.message(title, {message})
  end
  for i,line in ipairs(message) do
    message[i] = ui.WrappingTextLine {
      text = line;
      wrap_width = (ui.main_win.w/2):floor()
    }
  end

  local box = ui.Box {
    title = title;
    content = ui.VList(message);
    position = { 0.5, 0.5 };
  }
  function box:key_any()
    self:destroy()
    return true
  end

  ui.main_win:attach(box)
  ui.main_win:layout()
  return box
end

function ui.fill(rect, char)
  char = char or ' '
  tty.push(rect)
  for y=0,rect.h-1 do
    tty.put(0, y, char:rep(rect.w))
  end
  tty.pop()
end

function ui.sendEvent(key, evt)
  ui.screen:keyEvent(key, evt)
end
