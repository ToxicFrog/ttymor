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
  return "<%s$%d:%s>" % { self._TYPE, self.id or 0, self.name or "???" }
end

function Entity:__repr(...)
  local state = {}
  for k,v in pairs(self) do
    if type(k) ~= 'number' then
      state[k] = v
    end
  end
  return "Entity '%s' %s" % { self._TYPE, repr(state, ...) }
end

function Entity:frob(frobber)
  local node = { name = self.name, expanded = true }
  for i,cmp in ipairs(self) do
    if cmp.__frob then
      table.insert(node, cmp.__frob(self, frobber) or nil)
    end
  end
  if #node > 0 then
    return node
  end
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

local entity_types = require 'entities'

return function(typename)
  local def = assertf(entity_types[typename], 'no EntityType found: %s', typename)
  return function(data)
    -- "data" is the initializer for this specific entity
    -- it consists of a few top-level fields like id and name, and 0 or more
    -- component name => component setting mappings.

    -- "def" is the definition for this EntityType. It has two fields, 'defaults',
    -- the default top-level values like name, and 'components', a list of
    -- component definitions. Each component definition has three parts:
    --  methods, which are copied into the Entity and are not allowed to collide
    --  meta, which are appended to the Entity's array-part
    --  defaults, the default settings for that component in this entity type

    data._TYPE = typename
    table.merge(data, def.defaults, "ignore")
    table.merge(data, Entity, 'ignore')

    for i,component in ipairs(def.components) do
      data[i] = component.meta
      data[component.name] = data[component.name] or {}
      setmetatable(data[component.name], {__index = component.defaults})
      table.merge(data, component.methods, 'error')
    end

    for i,cmp in ipairs(data) do
      if cmp.__init then
        log.error('Calling %s:%s:__init', typename, cmp.__name)
        cmp.__init(data)
      end
    end

    -- When we're done here, the entity's array part contains the list of
    -- components, in order; each value in this list is a table of methods
    -- exposed by that component. The table part contains the top-level fields
    -- plus a field for each component, containing the settings for that
    -- component, copied from the defaults and shallow-overridden by the values
    -- in the entity constructor.
    return setmetatable(data, Entity)
  end
end
