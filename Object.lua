Object = {}
local ClassMT = {}

function ClassMT:__call(...)
	local obj = setmetatable({}, self)
	obj:__init(...)
	return obj
end

function Object:subclass(def)
	table.merge(def, self, 'ignore')
	def.__index = def
	setmetatable(def, ClassMT)
	return def
end

function Object:__init(kvs)
	table.merge(self, kvs, 'overwrite')
end

setmetatable(Object, ClassMT)
return Object
