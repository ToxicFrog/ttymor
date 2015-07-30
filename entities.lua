-- Master file of entity constructors.
local entities = {}

local function EntityType(name)
  return function(proto)
    entities[name] = proto
  end
end

local function Component(name)
  return function(proto)
    return { name = name, proto = proto }
  end
end

EntityType 'Player' {
  name = 'eyebrows';
  Component 'render' { face = '@'; style = 'v' };
  Component 'control' {};
  Component 'position' {};
}

EntityType 'Wall' {
  name = 'wall';
  Component 'render' { face = '#' };
}

EntityType 'Floor' {
  name = 'floor';
  Component 'render' { face = '.' }
}

EntityType 'Map' {
  name = "<unknown level>";
  Component 'map' {};
}

return entities
