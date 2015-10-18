-- Built-in entity types not read from the dredmor XML files.
local component = entity.component

entity.register 'Player' {
  name = 'player';
  component 'Render' { face = '@'; style = 'v' };
  component 'Control' {};
  component 'Position' {};
  component 'Blocker' { fly = true; walk = true; };
}

entity.register 'Wall' {
  name = 'wall';
  component 'Render' { face = '▒' };
  component 'Blocker' { fly = true; walk = true; };
}
entity.register 'InvisibleWall' {
  name = 'floor';
  component 'Render' { face = '.'; style = 'v' };
  component 'Blocker' { fly = true; walk = true; };
}

entity.register 'Water' {
  name = 'water';
  component 'Render' { face = '≈'; colour = {0,128,255} };
  component 'Blocker' { walk = true; };
}
entity.register 'Goo' {
  name = 'goo';
  component 'Render' { face = '≈'; colour = {0,255,0} };
  component 'Blocker' { walk = true; };
}
entity.register 'Ice' {
  name = 'ice';
  component 'Render' { face = '≈'; colour = {128,255,0} };
  component 'Blocker' { walk = true; };
}
entity.register 'Lava' {
  name = 'lava';
  component 'Render' { face = '≈'; colour = {255,64,0} };
  component 'Blocker' { walk = true; };
}

entity.register 'Floor' {
  name = 'floor';
  component 'Render' { face = '.' }
}

entity.register 'TestObject' {
  name = "test object";
  component 'Render' { face = '?' };
  component 'Position' {};
}

entity.register 'Door' {
  name = 'door';
  component 'Position' {};
  component 'Door' {};
  component 'Render' { face='!'; colour = {0xFF,0x99,0x33} };
}
