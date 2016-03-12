-- API for interacting with the entity registration/creation system.
-- For the behaviour of individual Entity instances, see game/Entity.lua
-- For built in entity types, see builtins.lua

local Entity = require 'game.Entity'
entity = {}

local entity_types = {}

-- create a new instance of a named entity.
-- entity.create { type = 'Wall'; Render = {...}; Blocker = {...} }
-- This is called by the save file loader to deserialize the entities stored in
-- it, and is also the basis of entity.create().
function entity.load(init)
  -- "init" is the initializer for this specific entity
  -- it consists of a few top-level fields like id and name, and 0 or more
  -- component name => component setting mappings.
  -- One of the top-level fields, 'type', tells us what EntityType to load.

  -- "def" is the definition for this EntityType. It has two fields, "fields"
  -- and "components".
  local def = assertf(entity_types[init.type], 'no EntityType found: %s', init.type)

  -- To turn init+def into an actual Entity, we need to set up two things.
  -- For the top level fields, we assign Entity as the metatable for init,
  -- and set _DEF to point to the def table, so that Entity:__index can fall
  -- back to it.
  -- For the components, we create an empty table for each component that
  -- isn't already listed in init, and __index it to the corresponding component
  -- in type.

  -- Then we just need to run the registered component initializers and we're done!

  -- Set up __index for top level & metamethods
  init._DEF = def
  setmetatable(init, Entity)

  -- Set up __index for individual components
  for k,v in pairs(def.components) do
    init[k] = init[k] or {}
    setmetatable(init[k], v)
  end

  -- Initialize table of children
  init.children = init.children or {}
  for id,ent in pairs(init.children) do
    ent._parent = Ref(init.id)
  end

  -- At this point, the entity object contains all those top-level fields that
  -- differ from the EntityType, and __index provides the missing ones, as
  -- well as all methods provided by the components.
  -- Message handlers are stored in top level arrays; e.g. init.__frob is an
  -- array of all the __frob handlers provided by its components. FIXME: we
  -- need a less ugly way of specifying message handlers.
  -- Individual component fields (e.g. init.Item) are also tables, __indexed
  -- to the corresponding component definition in the EntityType.
  return init
end

-- Create a new entity from scratch and initialize it.
function entity.create(init)
  local ent = entity.load(init)
  ent:message "init"
  return ent
end

-- Register a new entity type. It can then be instantiated with entity.create { type = 'name'; ...}
-- Registration is a curried function taking a name and then a table of constructor data.
-- entity.register 'Wall' {
--   name = 'wall';
--   Render = {...};
--   Blocker = {...};
--   ...
-- }
-- There is at present no support for inheriting from other entity types, a la SS2.
function entity.register(name)
  log.debug('Registering entity type %s', name)
  return function(init)
    local defaults = {}   -- default top-level field values, including methods
    local components = {} -- component-specific data

    for name,component in pairs(init) do
      if not name:match('^[A-Z]') then
        -- field is not a component initializer
        defaults[name] = component
      else
        -- field is a component initializer. Load the component definition.
        components[name] = component
        component.__index = component

        local def = require('components.'..name)
        for k,v in pairs(def) do
          if type(k) == 'string' and k:match('^__') then
            -- message handlers go into a top level collection with that name; e.g. for
            -- the __frob message, individual handlers are in defaults.__frob
            defaults[k] = defaults[k] or {}
            table.insert(defaults[k], v)
          elseif type(v) == 'function' then
            -- functions go directly into the top level; name collisions are an error
            assert(defaults[k] == nil)
            defaults[k] = v
          elseif component[k] == nil then
            -- everything else goes in component-specific data, but only if it
            -- hasn't been overriden.
            component[k] = v
          end
        end
      end
    end

    entity_types[name] = { defaults = defaults, components = components }
  end
end
