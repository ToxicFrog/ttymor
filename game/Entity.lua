require 'repr'

-- Core implementation of the entity-component system.
local Entity = {}

-- Calling ent:foo(...) is equivalent to iterating the components in the entity
-- and calling component:foo(entity, ...) on each one that supports foo.
-- If any of them return values, iteration stops immediately and those values
-- are returned.
-- TODO: is this really the API I want? Value returns in particular are kind
-- of gross.
function Entity:__index(k)
  local fns = {}
  for i,component in ipairs(self) do
    if component[k] then
      fns[#fns+1] = component[k]
    end
  end
  assertf(#fns > 0, '%s: read of nonexistent field %s', self, k)
  self[k] = function(self, ...)
    for _,fn in ipairs(fns) do
      local rv = { fn(self, ...) }
      if #rv > 0 then
        return unpack(rv)
      end
    end
  end
  return self[k]
end

function Entity:__tostring()
  return "<%s$%d:%s>" % { self._TYPE, self.id or 0, self.name or "???" }
end

function Entity:__repr(...)
  return "Entity '%s' %s" % { self._TYPE, rawrepr(self, ...) }
end

local entity_types = require 'entities'

return function(type)
  local def = assertf(entity_types[type], 'no EntityType found: %s', type)
  return function(data)
    -- "data" is the initializer for this specific entity
    -- it consists of a few top-level fields like id and name, and 0 or more
    -- component name => component setting mappings
    -- "def" is the definition for this EntityType. It consists of a list of
    -- component definitions, each one containing the component name and the
    -- default settings for the component, in the order they should be searched
    -- when resolving methods at runtime.
    data._TYPE = type
    table.merge(data, def, "ignore")
    for i,component in ipairs(def) do
      local impl = require('components.'..component.name)
      data[i] = impl
      data[component.name] = data[component.name] or {}
      table.merge(data[component.name], component.proto, "ignore")
      table.merge(data[component.name], impl.defaults or {}, "ignore")
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
