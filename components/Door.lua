-- A door. It can be open or shut. When shut it blocks both movement and LOS.
-- It has two faces, face_open and face_shut, and displays one or the other depending
-- on its state.
-- For this reason, it implements :render. Entities with a door component should
-- place it before the render component so it can affect the rendering code.

local Door = {
  face_open = '■';
  face_shut = '+';
  open = false;
  segments = {};
}

function Door:msg_init()
  self.Render.face = self.Door[self.Door.open and 'face_open' or 'face_shut']
end

function Door:open(state)
  if state ~= nil and state ~= self.Door.open then
    game.log('The door %s.', state and 'opens' or 'closes')
    for _,segment in ipairs(self.Door.segments) do
      segment.Door.open = state
      segment.Render.face = segment.Door[state and 'face_open' or 'face_shut']
    end
  end
  return self.Door.open
end

function Door:blocks()
  return not self:open()
end

function Door:touchedBy(ent)
  if ent.type ~= 'Player' then return end
  self:open(true)
end

function Door:msg_verb_open_by(ent)
  self:open(true)
end

function Door:msg_verb_close_by(ent)
  self:open(false)
end

-- TODO: expose the "close" verb only for the hinges of the door, not the middle
function Door:msg_verbs(verbs)
  if self:open() then
    for i,segment in ipairs(self.Door.segments) do
      local map = self._parent
      local x,y = map:positionOf(segment)
      if map:blocked(x, y, 'walk') then
        return verbs
      end
    end
    verbs.close = true
  else
    verbs.open = true
  end
  return verbs
end

return Door
