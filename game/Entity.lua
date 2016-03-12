require 'repr'

-- Core implementation of the entity-component system.
local Entity = {}

-- ent[<component name>] holds the state for that component
-- ent[<method name>] is either a top-level entity method, like :frob, or is
-- a method from a component; it is an error for multiple components to provide
-- methods with the same name.
-- ent.id is the entity ID, and ent.name the entity name
-- ent.message_handlers[<message name>] is a list of handlers for messages of
-- that type. TODO: provide a way for Entity itself to register a message handler.

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
  for i,handler in ipairs(self.message_handlers[type] or {}) do
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

-- Claim the given entity (which must be a naked entity, not a Ref)
-- as a child of this one.
function Entity:claim(child)
  self.children[child.id] = child
  child._parent = Ref(self)
  self:message("claim", child)
  child:message("claimed_by", self)
end

-- Release the given entity from our children table. Returns the naked entity.
-- Called with no arguments, releases self from its parent.
function Entity:release(child)
  if not child then
    return self._parent:release(self)
  end
  local entity = assertf(self.children[child.id], "%s attempted to release %s, which is not its child", self, child)
  self.children[child.id] = nil
  entity._parent = nil
  self:message("release", child)
  child:message("released_by", self)
  return entity
end

-- Delete the given entity. Works by unregistering it from the global entity
-- table, then releasing it from its parent and *not* returning it.
function Entity:delete()
  self:release()
  self:unregister()
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
