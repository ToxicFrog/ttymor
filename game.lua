local repr = require "repr"

game = {}

local entities = {}

function game.new()
  entities = {}
end

function game.load(file)
  entities = assert(loadfile(file))()
end

function game.save(file)
  io.writefile(file, "return "..repr.repr(entities))
end

function game.add(entity)
  entity.id = entity.id or #entities+1
  assert(not entities[entity.id], "attempt to add entity with duplicate id")
  entities[entity.id] = Entity(entity)
  return game.ref(entity.id)
end

function game.get(id)
  return game.ref(assert(entities[id], "no such entity: %d" % id))
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
    return game.ref(id.id)
  end
  return setmetatable({ _REF = true; id = id; }, ref_mt)
end
