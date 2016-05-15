require "repr"
require 'game.entity'

-- These must be global for game loading. TODO: fix
Ent = entity.load
Ref = require 'game.Ref'

game = {}
game.log = require 'game.Log' {}

local state = {}

--
-- Gamestate initialization and save/load
--

function game.new(name)
  require 'builtins'
  state = {
    name = name;
    entities = {};   -- master id => object lookup table
    names = {};      -- lookup by name for name-registered entities
    singletons = {}; -- entities owned by the game state rather than by a map. TODO: better name.
    maps = {};
    next_id = 0;
  }

  local map = game.createMap {
    name = "DL01";
    depth = 1;
    w = 100; h = 100;
    start = "Starting Room";
  }

  local cx,cy = (map.Map.w/2):floor(),(map.Map.h/2):floor()
  map:createAt(cx-1, cy-3, { type = 'Tofu' })
  map:createAt(cx-1, cy-4, { type = 'Tofu'; Item = { count = 3 }})
  map:createAt(cx-2, cy-3, { type = 'Aged Cheese'; Item = { stackable = false }})
  map:createAt(cx-2, cy-4, { type = 'Aged Cheese'; Item = { stackable = false, count = 2 }})

  local player = map:createAt(cx-1, cy-4, { type = 'Player' })

  game.log:clear()

  return game.registerNamedUnique('player', player)
end

function game.objectPath(file, per_game)
  if per_game then
    assert(state.name, 'game.objectPath(..., true) called when no game is loaded')
    return '%s/%s.sav/%s' % { flags.parsed.config_dir, state.name, file }
  end
  return '%s/%s' % { flags.parsed.config_dir, file }
end

function game.saveObject(file, object, per_game)
  return io.writefile(game.objectPath(file, per_game), 'return '..repr(object))
end

function game.loadObject(file, per_game)
  return assert(loadfile(game.objectPath(file, per_game)))()
end

function game.loadOptional(file, per_game)
  if io.exists(game.objectPath(file, per_game)) then
    return game.loadObject(file, per_game)
  end
end

function game.name()
  return state.name
end

function game.save()
  log.info("Saving game to %s/%s.sav", flags.parsed.config_dir, state.name)
  os.execute("mkdir -p '%s/%s.sav'" % { flags.parsed.config_dir, state.name })
  for name,map in pairs(state.maps) do
    game.saveObject('%s.map' % name, map, true)
  end
  local save = table.merge(
      { maps = table.mapv(state.maps, f' => true'); entities = {}; },
      state, 'ignore')

  game.saveObject("state", save, true)
end

function game.load(name)
  require 'builtins'
  log.info("Loading game from %s/%s.sav", flags.parsed.config_dir, name)
  state = { name = name }

  game.log:clear()
  table.merge(state, game.loadObject("state", true), "overwrite")
  for _,entity in pairs(state.singletons) do
    entity:register()
  end

  for name,map in pairs(state.maps) do
    state.maps[name] = game.loadObject('%s.map' % name, true)
    state.maps[name]:register()
  end
end

--
-- Map management
--

-- Create a map with the given depth and name. Return a Ref to it.
function game.createMap(init)
  assertf(init.name, "anonymous maps are not permitted")
  assertf(not state.maps[init.name], "map '%s' already exists", init.name)

  local map = entity.create {
    type = 'Map';
    name = init.name;
    id = game.nextID();
    Map = init;
  }

  local generator = require 'mapgen.dredmor' ()
  generator:generate(map, map.Map.start)
  map:register()

  state.maps[init.name] = map
  return Ref(map)
end

-- TODO: implement unloadMap()

--
-- Entity management
--

function game.nextID()
  state.next_id = state.next_id + 1
  return state.next_id
end

-- Register an entity, owned by a map, in the global entity lookup table.
-- This holds a reference to the actual entity, not a Ref to it!
function game.register(ent)
  state.entities[ent.id] = ent
end

-- Unregister a previously registered entity.
function game.unregister(ent)
  state.entities[ent.id] = nil
end

-- Create a singleton with the given name and type, or return it if it already
-- exists. Returns a Ref.
function game.createSingleton(name)
  return function(data)
    if state.names[name] then
      assertf(state.names[name].type == data.type,
          "mismatched types initializing singleton %s: %s ~= %s",
          name, data.type, state.names[name].type)
    else
      data.id = game.nextID()
      local ent = entity.create(data)
      state.singletons[data.id],state.names[name] = ent,ent
      game.register(ent)
    end
    return state.names[name]
  end
end

-- Register a singleton by the given name without claiming ownership of it.
function game.registerNamedUnique(name, entity)
  assertf(not state.names[name], "attempt to double-register unique named entity with name %s", name)
  state.names[name] = Ref(entity)
  return state.names[name]
end

-- Get an entity by numeric ID or singleton name. Returns a Ref.
function game.get(id)
  if type(id) == 'number' then
    return Ref(assertf(state.entities[id], "no entity with id: %d", id))
  elseif type(id) == 'string' then
    return Ref(assertf(state.names[id], "no entity named %s", id))
  else
    error("Invalid argument %s to game.get", name)
  end
end

-- Get an entity by numeric ID. Returns the actual entity, not a Ref. This is
-- used internally by Ref to get the underlying entity to operate on and should
-- not be called by anything else.
function game.rawget(id)
  return state.entities[id]
end

