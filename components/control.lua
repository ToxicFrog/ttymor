-- Component for keyboard control of the containing entity.
local control = {}

function control:turn(ent)
  game.log("--- turn: %s", ent)
  local cmd = io.read(1)
  local x,y = ent:position()
  if cmd == 'q' then
    game.save("test.sav")
    shutdown()
  elseif cmd == 'w' then
    ent:move(0, -1)
  elseif cmd == 's' then
    ent:move(0, 1)
  elseif cmd == 'a' then
    ent:move(-1, 0)
  elseif cmd == 'd' then
    ent:move(1, 0)
  end
end

return control
