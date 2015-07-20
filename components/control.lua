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
  elseif cmd == 'key:T' then
    tty.colour(0, 255, 255)
    tty.bgcolour(0, 0, 0)
    local node = ui.tree {
      text = "TOP LEVEL DO NOT DISPLAY";
      title = "Test Menu";
      { text = "save" };
      { text = "load" };
      { text = "quit" };
      { text = "options"; expanded = true;
        { text = "sound" };
        { text = "music" };
        { text = "tiles" };
        { text = "controls";
          { text = "move" };
          { text = "attack" };
        };
      };
    }
    game.log("tree: %s", node and node.text or '<<canceled>>')
  else
    game.log('command: %s', cmd)
  end
end

return control
