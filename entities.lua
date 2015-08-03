-- Master file of entity constructors.
local entities = {}

local function EntityType(name)
  return function(proto)
    proto.type = name
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
  Component 'render' { face = '▒' };
}
EntityType 'InvisibleWall' {
  name = 'floor';
  Component 'render' { face = '.'; style = 'v' };
}
EntityType 'Water' {
  name = 'liquid';
  Component 'render' { face = '≈'; colour = {0,128,255} };
}
EntityType 'Goo' {
  name = 'liquid';
  Component 'render' { face = '≈'; colour = {0,255,0} };
}
EntityType 'Ice' {
  name = 'liquid';
  Component 'render' { face = '≈'; colour = {128,255,0} };
}
EntityType 'Lava' {
  name = 'liquid';
  Component 'render' { face = '≈'; colour = {255,64,0} };
}

EntityType 'Floor' {
  name = 'floor';
  Component 'render' { face = '.' }
}

EntityType 'Map' {
  name = "<unknown level>";
  Component 'map' {};
}

EntityType 'TestObject' {
  name = "test object";
  Component 'render' { face = '?' };
  Component 'position' {};
}

EntityType 'Door' {
  name = 'door';
  Component 'position' {};
  Component 'door' {};
  Component 'render' { face='!'; colour = {0xFF,0x99,0x33} };
}

return entities
