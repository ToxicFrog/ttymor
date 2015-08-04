require 'repr'
--local entity_types = require 'entities'

-- Core implementation of the entity-component system.
local Entity_MT = {}
local function Entity(data)
  return setmetatable(data, Entity_MT)
end

-- Calling ent:foo(...) is equivalent to iterating the components in the entity
-- and calling component:foo(entity, ...) on each one that supports foo.
-- If any of them return values, iteration stops immediately and those values
-- are returned.
-- TODO: is this really the API I want? Value returns in particular are kind
-- of gross.
function Entity_MT:__index(k)
  return function(self, ...)
    for i,component in ipairs(self) do
      if component[k] then
        local rv = { component[k](component, self, ...) }
        if #rv > 0 then
          return unpack(rv)
        end
      end
    end
  end
end

function Entity_MT:__tostring()
  return "<%s$%d:%s>" % { self.type, self.id or 0, self.name or "???" }
end

function Entity_MT:__repr(...)
  return "Entity %s" % rawrepr(self, ...)
end

return Entity
