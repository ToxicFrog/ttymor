require "repr"
local Map = require 'game.Map'

-- These two must be global for game loading. TODO: fix
Entity = require 'game.Entity'
Ref = require 'game.Ref'

game = {}

local state = {}

--
-- Gamestate initialization and save/load
--

function game.new(name)
  state = {
    name = name;
    entities = {};
    log = {};
    singletons = {};
    maps = {};
    next_id = 0;
  }

  local void = game.createMap(0, "the void")
  local map = game.createMap(1, "level 1")
  map:generate(100, 100, "Starting Room")

  local player = game.createSingleton('Player', 'player') {}

  player:setMap(map)
  player:moveTo((map.w/2):floor()-1, (map.h/2):floor()-4)

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
  for depth,map in pairs(state.maps) do
    map:save()
  end
  local save = table.merge(
      { maps = table.mapv(state.maps, f' => true'); entities = {} },
      state, 'ignore')

  game.saveObject("state", save, true)
end

function game.load(name)
  log.info("Loading game from %s/%s.sav", flags.parsed.config_dir, name)
  state = { name = name }

  table.merge(state, game.loadObject("state", true), "overwrite")

  for depth,map in pairs(state.maps) do
    state.maps[depth] = false
    game.createMap(depth):load()
  end
end

--
-- Map management
--

function game.createMap(depth, name)
  assertf(not state.maps[depth], "map %d already exists", depth)

  local map = Map {
    name = name or "Level "..depth;
    depth = depth;
  }
  state.maps[depth] = map
  return map
end

function game.getMap(n)
  assertf(type(n) == 'number', "bad argument to getMap: %s (%s)", n, type(n))
  return assertf(state.maps[n], "no map at depth %d", n)
end

--
-- Log management
--

function game.log(line, ...)
  table.insert(state.log, line:format(...))
end

function game.getLog()
  return state.log
end

function game.nextID()
  state.next_id = state.next_id + 1
  return state.next_id
end

--
-- Entity management
--

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
function game.createSingleton(type, name)
  return function(data)
    if state.singletons[name] then
      assertf(state.singletons[name]._TYPE == type,
          "mismatched types initializing singleton %s: %s ~= %s",
          name, type, state.singletons[name]._TYPE)
      return state.singletons[name]
    else
      -- all singletons are stored in map 0, the persistent map
      state.singletons[name] = game.getMap(0):create(type)(data)
    end
    return state.singletons[name]
  end
end

-- Get an entity by numeric ID or singleton name. Returns a Ref.
function game.get(id)
  if type(id) == 'number' then
    return Ref(assertf(state.entities[id], "no such entity: %d", id))
  elseif type(id) == 'string' then
    return assertf(state.singletons[id], "no singleton named %s", id)
  else
    errorf("Invalid argument %s to game.get", name)
  end
end

-- Get an entity by numeric ID. Returns the actual entity, not a Ref. This is
-- used internally by Ref to get the underlying entity to operate on and should
-- not be called by anything else.
function game.rawget(id)
  return state.entities[id]
end

