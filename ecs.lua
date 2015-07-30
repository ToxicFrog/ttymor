require 'repr'

-- Core implementation of the entity-component system.
local Entity_MT = {}
function Entity(data)
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
  return "<%s>$%d" % { self.name or "???", self.id or 0 }
end

function Entity_MT:__repr(...)
  return "Entity %s" % rawrepr(self, ...)
end

function Component(name)
  local impl = require("components."..name)
  assert(type(impl) == 'table')
  impl._NAME = impl._NAME or name
  impl._MT = impl._MT or {
    __index = impl;
    __repr = function(data, ...)
      return "Component '%s' %s" % { impl._NAME, rawrepr(data, ...) }
    end;
    __tostring = function(data)
      return "Component[%s]" % impl._NAME
    end;
  }
  return function(data)
    return setmetatable(data, impl._MT)
  end
end
