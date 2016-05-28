local Ref = {}

local function deref(ref)
  return assertf(game.rawget(ref.id),
    "Entity %d does not exist, but we tried to deref it!", ref.id)
end

function Ref:__tostring()
  return tostring(deref(self))
end

function Ref:__index(k)
  return deref(self)[k]
end

function Ref:__newindex()
  error('Attempt to set uninitialized field on %s', self)
end

function Ref:__repr()
  return 'Ref(%d)' % self.id
end

function Ref:__ipairs()
  return ipairs(deref(self))
end

function Ref:__pairs()
  return pairs(deref(self))
end

local function new(id)
  assert(id, "no argument passed to Ref")
  if type(id) ~= 'number' then
    return new(id.id)
  end
  return setmetatable({ _REF = true; id = id; }, Ref)
end

return new
