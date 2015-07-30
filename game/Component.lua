require 'repr'

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

return Component
