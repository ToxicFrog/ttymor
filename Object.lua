Object = {}
Object.__class = Object
local ClassMT = {}

function ClassMT:__call(...)
  -- Copy all non-meta fields into the object
  local obj = {}
  for k,v in pairs(self) do
    if type(k) ~= 'string' or not k:match('^__') then
      obj[k] = v
    end
  end
  setmetatable(obj, self)
  obj:callmetamethod('__init', ...)
  return obj
end

function Object:__init(kvs)
  table.merge(self, kvs, 'overwrite')
end

function Object:callmetamethod(name, ...)
  return getmetafield(self, name)(self, ...)
end

function Object:subclass(def)
  table.merge(def, self, 'ignore')
  def.__class = def
  setmetatable(def, ClassMT)
  return def
end

setmetatable(Object, ClassMT)
return Object
