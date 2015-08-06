-- Master file of entity constructors.
local entities = {}

local function EntityType(name)
  return function(proto)
    proto._TYPE = name
    entities[name] = proto
  end
end

local function Component(name)
  return function(proto)
    return { name = name, proto = proto }
  end
end

EntityType 'Player' {
  name = 'player';
  Component 'Render' { face = '@'; style = 'v' };
  Component 'Control' {};
  Component 'Position' {};
}

EntityType 'Wall' {
  name = 'wall';
  Component 'Render' { face = '▒' };
}
EntityType 'InvisibleWall' {
  name = 'floor';
  Component 'Render' { face = '.'; style = 'v' };
}
EntityType 'Water' {
  name = 'water';
  Component 'Render' { face = '≈'; colour = {0,128,255} };
}
EntityType 'Goo' {
  name = 'goo';
  Component 'Render' { face = '≈'; colour = {0,255,0} };
}
EntityType 'Ice' {
  name = 'ice';
  Component 'Render' { face = '≈'; colour = {128,255,0} };
}
EntityType 'Lava' {
  name = 'lava';
  Component 'Render' { face = '≈'; colour = {255,64,0} };
}

EntityType 'Floor' {
  name = 'floor';
  Component 'Render' { face = '.' }
}

EntityType 'TestObject' {
  name = "test object";
  Component 'Render' { face = '?' };
  Component 'Position' {};
}

EntityType 'Door' {
  name = 'door';
  Component 'Position' {};
  Component 'Door' {};
  Component 'Render' { face='!'; colour = {0xFF,0x99,0x33} };
}

return entities
