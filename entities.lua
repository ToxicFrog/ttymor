-- Master file of entity constructors.
local entities = {}

local function EntityType(name)
  return function(proto)
    local components = {}
    for i,v in ipairs(proto) do
      components[i] = v
      proto[i] = nil
    end
    entities[name] = { defaults = proto, components = components }
  end
end

local function Component(name)
  local impl = require('components.'..name)
  local meta,methods,defaults = {},{},{}
  for k,v in pairs(impl) do
    if type(k) == 'string' and k:match('^__') then
      meta[k] = v
    elseif type(v) == 'function' then
      methods[k] = v
    else
      defaults[k] = v
    end
  end
  meta.__name = name
  return function(proto)
    table.merge(proto, defaults, 'ignore')
    return {
      name = name;
      meta = meta;
      methods = methods;
      defaults = proto;
    }
  end
end

EntityType 'Player' {
  name = 'player';
  Component 'Render' { face = '@'; style = 'v' };
  Component 'Control' {};
  Component 'Position' {};
  Component 'Blocker' { 'fly', 'walk' };
}

EntityType 'Wall' {
  name = 'wall';
  Component 'Render' { face = '▒' };
  Component 'Blocker' { 'fly', 'walk' };
}
EntityType 'InvisibleWall' {
  name = 'floor';
  Component 'Render' { face = '.'; style = 'v' };
  Component 'Blocker' { 'fly', 'walk' };
}
EntityType 'Water' {
  name = 'water';
  Component 'Render' { face = '≈'; colour = {0,128,255} };
  Component 'Blocker' { 'walk' };
}
EntityType 'Goo' {
  name = 'goo';
  Component 'Render' { face = '≈'; colour = {0,255,0} };
  Component 'Blocker' { 'walk' };
}
EntityType 'Ice' {
  name = 'ice';
  Component 'Render' { face = '≈'; colour = {128,255,0} };
  Component 'Blocker' { 'walk' };
}
EntityType 'Lava' {
  name = 'lava';
  Component 'Render' { face = '≈'; colour = {255,64,0} };
  Component 'Blocker' { 'walk' };
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
