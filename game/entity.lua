-- API for interacting with the entity registration/creation system.
-- For the behaviour of individual Entity instances, see game/Entity.lua
-- For built in entity types, see builtins.lua

local Entity = require 'game.Entity'
entity = {}

local entity_types = {}

-- create a new instance of a named entity.
-- entity.create 'Wall' { Render = {...}; Blocker = {...} }
function entity.create(typename)
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

-- Register a new entity type. It can then be instantiated with entity.create 'name' {...}
-- Registration is a curried function taking a name and then a table of constructor data.
-- entity.register 'Wall' {
--   name = 'wall';
--   entity.component 'Render' {...};
--   entity.component 'Blocker' {...};
--   ...
-- }
-- There is at present no support for inheriting from other entity types, a la SS2.
function entity.register(name)
  return function(proto)
    local components = {}
    for i,v in ipairs(proto) do
      components[i] = v
      proto[i] = nil
    end
    entity_types[name] = { defaults = proto, components = components }
  end
end

-- Register an individual component. Use only as part of entity.register (see above).
-- Why not just have entity.register take a component name => initializer mapping? Because
-- the order of components matters.
function entity.component(name)
  local impl = require('components.'..name)
  local meta,methods,defaults = {},{},{}
  for k,v in pairs(impl) do
    if type(k) == 'string' and k:match('^__') then
      meta[k] = v
    elseif type(v) == 'function' then
      methods[k] = v
    else
      defaults[k] = v
    end
  end
  meta.__name = name
  return function(proto)
    table.merge(proto, defaults, 'ignore')
    return {
      name = name;
      meta = meta;
      methods = methods;
      defaults = proto;
    }
  end
end
