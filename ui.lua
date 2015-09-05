ui = {}

ui.List = require 'ui.List'
ui.Window = require 'ui.Window'
ui.Tree = require 'ui.Tree'
ui.Box = require 'ui.Box'

function ui.init()
  local w,h = tty.init()

  ui.screen = ui.Window {
    name = "screen";
    x = 0; y = 0;
    w = w; h = h;
    position = 'fixed';
    visible = true;
    render = function(self)
      tty.colour(255, 255, 255, 0, 0, 0)
      tty.style('o')
      tty.clear()
    end;
  }

  -- log is upper right, 40 cols wide and half the screen high
  ui.log_win = require 'ui.log_win' {
    position = 'fixed';
    x = 0; y = 0;
    w = 40; h = (h/2):ceil();
  }
  ui.screen:attach(ui.log_win)

  -- HUD is just below log, same width
  ui.hud_win = require 'ui.hud_win' {
    position = 'fixed';
    x = 0; y = ui.log_win.h;
    w = 40; h = h - ui.log_win.h;
  }
  ui.setHUD('HUD', 'Test HUD content')
  ui.screen:attach(ui.hud_win)

  -- main view takes up the remaining space
  ui.main_win = require 'ui.main_win' {
    position = 'fixed';
    x = 40; y = 0;
    w = w - 40; h = h;
  }
  ui.screen:attach(ui.main_win)
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
  tty.colour(0, 255, 255)
  ui.tree {
    name = 'Main Menu';
    { name = 'Return to Game';
      help = 'Close the menu and return to the game in progress.' };
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
      activate = function() game.save(); return false; end;
      help = 'Save your game in progress.' };
    { name = 'Load Game';
      activate = function() game.load(game.name()); return false; end;
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
  tree = ui.Tree(tree)
  ui.main_win:attach(tree)
  tree:run()
  tree:destroy()
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
