require "repr"
local Entity = require 'game.Entity'
local Component = require 'game.Component'
local Map = require 'game.Map'
Ref = require 'game.Ref' -- must be global for game loading. TODO: fix

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

  local map = game.createMap(0, "test map")
  map:generate(100, 100)

  local player = game.createSingleton('Player', 'player') {}

  player:setMap(map)
  player:moveTo(10, 11)

  local tobj = game.getMap(0):create 'TestObject' {}
  tobj:setMap(map)
  tobj:moveTo(10, 12)

  local tobj = game.getMap(0):create 'TestObject' {}
  tobj:setMap(map)
  tobj:moveTo(11, 11)

  return player
end

function game.saveObject(file, object)
  return io.writefile('%s.sav/%s' % { state.name, file }, 'return '..repr(object))
end

function game.loadObject(file)
  return assert(loadfile('%s.sav/%s' % { state.name, file }))()
end

function game.save()
  os.execute("mkdir -p '%s'" % 'test.sav') -- at some point will be based on character name
  for depth,map in pairs(state.maps) do
    map:save()
  end
  local save = table.merge(
      { maps = table.mapv(state.maps, f' => true'); entities = {} },
      state, 'ignore')

  game.saveObject("state", save)
end

function game.load(name)
  state = { name = name }

  table.merge(state, game.loadObject("state"), "overwrite")

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
      assertf(state.singletons[name].type == type,
          "mismatched types initializing singleton %s: %s ~= %s",
          name, type, state.singletons[name].type)
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

