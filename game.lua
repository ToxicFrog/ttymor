require "repr"
local Entity = require 'game.Entity'
local Component = require 'game.Component'

flags.register "maps" {
  help = "Generate and keep in memory this many maps for debugging purposes";
  type = flags.number;
  default = 1;
}

game = {}

local entities,log,singletons,next_id

function game.new()
  entities = {}
  log = {}
  singletons = {}
  next_id = 1

  local player = game.createSingleton('Player', 'player') {}

  local map
  for i=1,flags.parsed.maps do
    map = game.create 'Map' {
      name = "Level "..i;
      w = 100; h = 100;
    }
    map:generate()
  end

  player:setMap(map)
  player:moveTo(10, 11)
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
    local proto = assert(entity_types[type], "no entity with type %s", type)

    local entity = table.copy(proto)
    for i,component in ipairs(entity) do
      entity[i] = Component(component.name)(component.proto)
    end
    table.merge(entity, data, "overwrite")

    entity.id,next_id = next_id,next_id+1
    assert(not entities[entity.id], "attempt to add entity with duplicate id")

    entities[entity.id] = Entity(entity)
    return game.ref(entity.id)
  end
end

function game.createSingleton(type, name)
  return function(data)
    if singletons[name] then
      assert(singletons[name].type == type,
          "mismatched types initializing singleton %s: %s ~= %s",
          name, type, singletons[name].type)
      return singletons[name]
    else
      singletons[name] = game.create(type)(data)
    end
    return singletons[name]
  end
end

function game.get(id)
  if type(id) == 'number' then
    return game.ref(assert(entities[id], "no such entity: %d" % id))
  else
    error("Invalid argument %s to game.get" % name)
  end
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
