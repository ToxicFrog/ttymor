local Ref = {}

function Ref:__tostring()
  return 'Ref[%s]' % tostring(self:deref())
end

function Ref:__index(k)
  return self:deref()[k]
end

function Ref:__repr()
  return 'Ref(%d)' % self.id
end

function Ref:__ipairs()
  return ipairs(self:deref())
end

function Ref:__pairs()
  return pairs(self:deref())
end

function Ref:__newindex()
  error('Attempt to set uninitialized field on %s', self)
end

function Ref:deref()
  return game.rawget(self.id)
end

local function new(id)
  assert(id, "no argument passed to Ref")
  if type(id) ~= 'number' then
    return new(id.id)
  end
  return setmetatable({ _REF = true; id = id; _game = game; }, Ref)
end

return new
