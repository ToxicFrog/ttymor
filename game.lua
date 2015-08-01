require "repr"
local Entity = require 'game.Entity'
local Component = require 'game.Component'

game = {}

local entities,log,singletons,next_id,maps

function game.createMap(depth, name)
  assertf(not maps[depth], "map %d already exists", depth)

  local map = game.create 'Map' {
    name = name or "Level "..depth;
  }
  maps[depth] = map
  return map
end

function game.new()
  entities,log,singletons,maps = {},{},{},{}
  next_id = 1

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
  table.insert(log, line:format(...))
end

function game.getLog()
  return log
end

function game.load(file)
  entities = assert(loadfile(file))()
  -- holy shit this is so busted
  local data = assert(loadfile(file..".non-entity"))()
  singletons,log,next_id = data.singletons,data.log,data.next_id
end

function game.save(file)
  io.writefile(file, "return "..repr(entities))
  io.writefile(file..".non-entity", "return "..repr {
    singletons = singletons;
    log = log;
    next_id = next_id;
  })
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

    entity.id,next_id = next_id,next_id+1
    assertf(not entities[entity.id], "attempt to add entity with duplicate id %d", entity.id)

    entities[entity.id] = Entity(entity)
    return game.ref(entity.id)
  end
end

function game.createSingleton(type, name)
  return function(data)
    if singletons[name] then
      assertf(singletons[name].type == type,
          "mismatched types initializing singleton %s: %s ~= %s",
          name, type, singletons[name].type)
      return singletons[name]
    else
      singletons[name] = game.getMap(0):create(type)(data)
    end
    return singletons[name]
  end
end

function game.get(id)
  if type(id) == 'number' then
    return game.ref(assertf(entities[id], "no such entity: %d", id))
  elseif type(id) == 'string' then
    return assertf(singletons[id], "no singleton named %s", id)
  else
    errorf("Invalid argument %s to game.get", name)
  end
end

function game.getMap(n)
  assertf(type(n) == 'number', "bad argument to getMap: %s (%s)", n, type(n))
  return assertf(maps[n], "no map at depth %d", n)
end

local function ref_index(ref, k)
  return entities[ref.id][k]
end

local function ref_repr(ref)
  return 'game.ref(%d)' % ref.id
end

local function ref_ipairs(ref)
  return ipairs(entities[ref.id])
end

local function ref_pairs(ref)
  return pairs(entities[ref.id])
end

local function ref_tostring(ref)
  return "Ref[%s]" % tostring(entities[ref.id])
end

local ref_mt = {
  __repr = ref_repr;
  __tostring = ref_tostring;
  __pairs = ref_pairs;
  __ipairs = ref_ipairs;
  __index = ref_index;
}

function game.ref(id)
  assert(id, "no argument passed to game.ref")
  if type(id) ~= 'number' then
    if id._REF then
      return id
    end
    return game.ref(id.id)
  end
  return setmetatable({ _REF = true; id = id; }, ref_mt)
end
