-- Component for keyboard control of the containing entity.
local control = {}

function control:turn(ent)
  game.log("--- turn: %s", ent)
  local cmd = ui.readkey()
  local x,y = ent:position()
  if cmd == 'quit' then
    game.save("test.sav")
    shutdown()
  elseif cmd == 'up' then
    ent:move(0, -1)
  elseif cmd == 'down' then
    ent:move(0, 1)
  elseif cmd == 'left' then
    ent:move(-1, 0)
  elseif cmd == 'right' then
    ent:move(1, 0)
  elseif cmd == 'key:B' then
    tty.colour(0, 0, 255)
    tty.bgcolour(255, 0, 0)
    ui.box(10, 10, 40, 10)
    tty.colour(255, 255, 255, 0, 0, 0)
    ui.readkey()
  elseif cmd == 'key:T' then
    tty.colour(0, 255, 255)
    tty.bgcolour(0, 0, 0)
    ui.tree {
      text = "TOP LEVEL DO NOT DISPLAY";
      { text = "save game" };
      { text = "load game" };
      { text = "quit game" };
      { text = "options";
        { text = "sound" };
        { text = "music" };
        { text = "tiles" };
        { text = "controls";
          { text = "move" };
          { text = "attack" };
        };
      };
    }
    ui.readkey()
  else
    game.log('command: %s', cmd)
  end
end

return control
