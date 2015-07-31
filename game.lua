require "repr"
local Entity = require 'game.Entity'
local Component = require 'game.Component'

flags.register "maps" {
  help = "Generate and keep in memory this many maps for debugging purposes";
  type = flags.number;
  default = 1;
}

game = {}

local entities = {}
local log = {}
local next_id = 1

function game.new()
  entities = {}
  log = {}
  next_id = 1

  local player = game.create 'Player' {}

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
end

function game.save(file)
  io.writefile(file, "return "..repr(entities))
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
