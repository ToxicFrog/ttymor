require "repr"
require 'game.entity'

-- These must be global for game loading. TODO: fix
Ent = entity.create
Ref = require 'game.Ref'

game = {}
game.log = require 'game.Log' {}

local state = {}

--
-- Gamestate initialization and save/load
--

function game.new(name)
  state = {
    name = name;
    entities = {};
    singletons = {};
    maps = {};
    next_id = 0;
  }

  local map = game.createMap {
    name = "DL01";
    depth = 1;
    w = 100; h = 100;
    start = "Starting Room";
  }

  local tofu = map:create { type = 'Tofu' }
  tofu:setMap(map)
  tofu:moveTo((map.Map.w/2):floor()-1, (map.Map.h/2):floor()-3)

  local player = game.createSingleton 'player' { type = 'Player' }
  player:setMap(map)
  player:moveTo((map.Map.w/2):floor()-1, (map.Map.h/2):floor()-4)

  game.log:clear()

  return player
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
  game.saveObject('singletons', state.singletons, true)
  for name,map in pairs(state.maps) do
    game.saveObject('%s.map' % name, map, true)
  end
  local save = table.merge(
      { maps = table.mapv(state.maps, f' => true'); entities = {}; singletons = {}; },
      state, 'ignore')

  game.saveObject("state", save, true)
end

function game.load(name)
  log.info("Loading game from %s/%s.sav", flags.parsed.config_dir, name)
  state = { name = name }

  game.log:clear()
  table.merge(state, game.loadObject("state", true), "overwrite")
  state.singletons = game.loadObject('singletons', true)
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
    if state.singletons[name] then
      assertf(state.singletons[name].type == data.type,
          "mismatched types initializing singleton %s: %s ~= %s",
          name, data.type, state.singletons[name].type)
    else
      data.id = game.nextID()
      state.singletons[name] = entity.create(data)
      game.register(state.singletons[name])
    end
    return Ref(state.singletons[name])
  end
end

-- Get an entity by numeric ID or singleton name. Returns a Ref.
function game.get(id)
  if type(id) == 'number' then
    return Ref(assertf(state.entities[id], "no such entity: %d", id))
  elseif type(id) == 'string' then
    return Ref(assertf(state.singletons[id], "no singleton named %s", id))
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

