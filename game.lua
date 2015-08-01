require "repr"
local Entity = require 'game.Entity'
local Component = require 'game.Component'
local Map = require 'game.Map'
Ref = require 'game.Ref'

game = {}

local state = {}

function game.createMap(depth, name)
  assertf(not state.maps[depth], "map %d already exists", depth)

  local map = Map {
    name = name or "Level "..depth;
    depth = depth;
  }
  state.maps[depth] = map
  return map
end

function game.new(name)
  state = {
    name = name;
    entities = {};
    log = {};
    singletons = {};
    maps = {};
    next_id = 1;
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

function game.log(line, ...)
  table.insert(state.log, line:format(...))
end

function game.getLog()
  return state.log
end

function game.saveObject(file, object)
  return io.writefile('%s.sav/%s' % { state.name, file }, 'return '..repr(object))
end

function game.loadObject(file)
  return assert(loadfile('%s.sav/%s' % { state.name, file }))()
end

function game.load(name)
  state = { name = name }

  table.merge(state, game.loadObject("state"), "overwrite")
  state.entities = game.loadObject("entities")

  for depth,map in pairs(state.maps) do
    state.maps[depth] = false
    game.createMap(depth):load()
  end
end

function game.save()
  os.execute("mkdir -p '%s'" % 'test.sav') -- at some point will be based on character name
  for depth,map in pairs(state.maps) do
    if map ~= true then
      map:save()
      state.maps[depth] = true
    end
  end
  game.saveObject("entities", state.entities)
  state.entities = nil
  game.saveObject("state", state)
end

local entity_types = require 'entities'
function game.create(type)
  return function(data)
    local proto = assertf(entity_types[type], "no entity with type %s", type)

    local entity = table.copy(proto)
    for i,component in ipairs(entity) do
      entity[i] = Component(component.name)(component.proto)
    end
    table.merge(entity, data, "overwrite")

    entity.id,state.next_id = state.next_id,state.next_id+1
    assertf(not state.entities[entity.id], "attempt to add entity with duplicate id %d", entity.id)

    state.entities[entity.id] = Entity(entity)
    return Ref(entity.id)
  end
end

function game.createSingleton(type, name)
  return function(data)
    if state.singletons[name] then
      assertf(state.singletons[name].type == type,
          "mismatched types initializing singleton %s: %s ~= %s",
          name, type, state.singletons[name].type)
      return state.singletons[name]
    else
      state.singletons[name] = game.getMap(0):create(type)(data)
    end
    return state.singletons[name]
  end
end

function game.get(id)
  if type(id) == 'number' then
    return Ref(assertf(state.entities[id], "no such entity: %d", id))
  elseif type(id) == 'string' then
    return assertf(state.singletons[id], "no singleton named %s", id)
  else
    errorf("Invalid argument %s to game.get", name)
  end
end

function game.rawget(id)
  return state.entities[id]
end

function game.getMap(n)
  assertf(type(n) == 'number', "bad argument to getMap: %s (%s)", n, type(n))
  return assertf(state.maps[n], "no map at depth %d", n)
end

