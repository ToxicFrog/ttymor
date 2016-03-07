require 'repr'

-- Core implementation of the entity-component system.
local Entity = {}

-- An entity is a table with both hash and array parts.
-- The array part is a list of tables, each one containing the metafields for
-- the corresponding component. This is primarily used for initialization (the
-- __init component metamethod) and frobbing (__frob).

-- The hash part holds a bunch of data:
-- ent[<component name>] holds the state for that component
-- ent[<method name>] is either a top-level entity method, like :frob, or is
-- a method from a component; it is an error for multiple components to provide
-- methods with the same name.
-- ent.id is the entity ID, and ent.name the entity name

function Entity:__tostring()
  return "<%s$%d:%s>" % { self.type, self.id or 0, self.name or "???" }
end

function Entity:__repr(...)
  local state = {}
  for k,v in pairs(self) do
    if type(k) ~= 'number' and not k:match('^_') then
      state[k] = v
    end
  end
  if not next(state.children) then
    state.children = nil
  end
  return "Ent %s" % { repr(state, ...) }
end

function Entity:__index(k)
  return Entity[k] or self._DEF.defaults[k]
end

function Entity:frob(frobber)
  local node = { name = self.name, expanded = true }
  self:message("frob", frobber, node)
  if #node > 0 then
    return node
  end
end

-- Call all registered message handlers on this entity of the given type.
function Entity:message(type, ...)
  for i,handler in ipairs(self["__"..type] or {}) do
    handler(self, ...)
  end
end

function Entity:register()
  game.register(self)
  for _,child in pairs(self.children) do
    child:register()
  end
end

function Entity:unregister()
  for _,child in pairs(self.children) do
    child:unregister()
  end
  game.unregister(self)
end

-- For API compatibility with TreeNode
function Entity:renderLabel(x, y)
  self:render(x, y)
  tty.put(x+1, y, ' '..(self.name or tostring(self)))
end

-- For API compatibility with TreeNode
function Entity:size()
  self.w = #(self.name or tostring(self)) + 2
  self.h = 1
end

return Entity
