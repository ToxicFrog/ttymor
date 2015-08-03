-- A door. It can be open or shut. When shut it blocks both movement and LOS.
-- It has two faces, face_open and face_shut, and displays one or the other depending
-- on its state.
-- For this reason, it implements :render. Entities with a door component should
-- place it before the render component so it can affect the rendering code.

local door = {
  face_open = '■';
  face_shut = '+';
  open = false;
}

function door:render(ent)
  for i,component in ipairs(ent) do
    if component._NAME == 'render' then
      component.face = self.open and self.face_open or self.face_shut
    end
  end
end

return door
