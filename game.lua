game = {}

local entities = {}

function game.new()
  entities = {}
end

function game.load(file)
  entities = assert(loadfile(file))()
end

function game.save(file)
  io.writefile(file, table.dump(entities))
end

function game.add(entity)
  entity.id = entity.id or #entities+1
  assert(not entities[entity.id], "attempt to add entity with duplicate id")
  entities[entity.id] = Entity(entity)
  return game.ref(entity.id)
end

function game.get(id)
  return game.ref(assert(entity[id], "no such entity: %d" % id))
end

local function ref_repr(self)
  return 'game.ref(%d)' % self.id
end

local function ref_ipairs(ref)
  return ipairs(getmetatable(ref).__index)
end

local function ref_pairs(ref)
  return pairs(getmetatable(ref).__index)
end

function game.ref(id)
  assert(entities[id])
  return setmetatable({ _REF = true }, {
    __index = entities[id];
    __repr = ref_repr;
    __pairs = ref_pairs;
    __ipairs = ref_ipairs;
    __tostring = function(ref)
      return "Ref[%s]" % tostring(getmetatable(ref).__index)
    end;
  })
end

function game.deref(ref)
  assert(rawget(ref, "_REF"))
  return getmetatable(ref).__index
end
