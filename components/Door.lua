-- A door. It can be open or shut. When shut it blocks both movement and LOS.
-- It has two faces, face_open and face_shut, and displays one or the other depending
-- on its state.
-- For this reason, it implements :render. Entities with a door component should
-- place it before the render component so it can affect the rendering code.

local Door = {
  defaults = {
    face_open = '■';
    face_shut = '+';
    open = false;
  };
}

function Door:open(state)
  local master = self.Door.master.Door
  if state ~= nil and state ~= master.open then
    game.log('The door %s.', state and 'opens' or 'closes')
    self.Door.master.Door.open = state
  end
  return self.Door.master.Door.open
end

function Door:render()
  self.Render.face = self:open() and self.Door.face_open or self.Door.face_shut
end

function Door:blocks()
  return not self:open()
end

function Door:touchedBy(ent)
  if ent._TYPE ~= 'Player' then return end
  self:open(true)
end

return Door
