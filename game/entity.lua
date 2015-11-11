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
  return function(init)
    -- "init" is the initializer for this specific entity
    -- it consists of a few top-level fields like id and name, and 0 or more
    -- component name => component setting mappings.

    -- "def" is the definition for this EntityType. It has two fields, "fields"
    -- and "components".

    -- To turn init+def into an actual Entity, we need to set up two things.
    -- For the top level fields, we assign Entity as the metatable for init,
    -- and <FIXME somehow point init at def>, so that Entity.__index falls back
    -- to the contents of def.
    -- For the components, we create an empty table for each component that
    -- isn't already listed in init, and __index it to the corresponding component
    -- in type.

    -- Then we just need to run the registered component initializers and we're done!

    -- Set up __index for top level & metamethods
    init._TYPE = typename
    init._DEF = def
    setmetatable(init, Entity)

    -- Set up __index for individual components
    for k,v in pairs(def.components) do
      init[k] = init[k] or {}
      setmetatable(init[k], v)
    end

    -- Run initializers
    for _,fn in ipairs(init.__init or {}) do
      fn(init)
    end

    -- At this point, the entity object contains all those top-level fields that
    -- differ from the EntityType, and __index provides the missing ones, as
    -- well as all methods and metamethods provided by the components.
    -- Metamethods are stored in top level arrays; e.g. init.__frob is an array
    -- of all the __frob metamethods provided by its components.
    -- Individual component fields (e.g. init.Item) are also tables, __indexed
    -- to the corresponding component definition in the EntityType.
    return init
  end
end

local function loadComponent(name)
  local fullname = 'components.'..name
  if not package.loaded[fullname] then
    local def = require(fullname)
    local metamethods,methods,defaults = {},{},{}
    for k,v in pairs(def) do
      if type(k) == 'string' and k:match('^__') then
        metamethods[k] = v
      elseif type(v) == 'function' then
        methods[k] = v
      else
        defaults[k] = v
      end
    end
    package.loaded[fullname] = {
      defaults = defaults;
      name = name;
      metamethods = metamethods;
      methods = methods;
    }
  end
  return package.loaded[fullname]
end

-- Register a new entity type. It can then be instantiated with entity.create 'name' {...}
-- Registration is a curried function taking a name and then a table of constructor data.
-- entity.register 'Wall' {
--   name = 'wall';
--   Render = {...};
--   Blocker = {...};
--   ...
-- }
-- There is at present no support for inheriting from other entity types, a la SS2.
function entity.register(name)
  return function(init)
    local components = {}
    for name,cmp in pairs(init) do
      if name:match('^[A-Z]') then
        -- keys starting with capital letters are component initializers
        init[name],components[name] = nil,cmp
        local def = loadComponent(name)
        table.merge(cmp, def.defaults, "ignore")
        cmp.__index = cmp
        table.merge(init, def.methods, "error")
        for k,v in pairs(def.metamethods) do
          init[k] = init[k] or {}
          table.insert(init[k], v)
        end
      end
    end

    entity_types[name] = { defaults = init, components = components }
  end
end
