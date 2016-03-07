-- Built-in entity types not read from the dredmor XML files.
entity.register 'Player' {
  name = 'player';
  Render = { face = '@'; style = 'v' };
  Control = {};
  Position = {};
  Blocker = { fly = true; walk = true; };
  Inventory = {};
}

entity.register 'Map' {
  name = 'map';
  Map = {};
}

entity.register 'Wall' {
  name = 'wall';
  Render = { face = '▒' };
  Blocker = { fly = true; walk = true; };
}
entity.register 'InvisibleWall' {
  name = 'floor';
  Render = { face = '.'; style = 'v' };
  Blocker = { fly = true; walk = true; };
}

entity.register 'Water' {
  name = 'water';
  Render = { face = '≈'; colour = {0,128,255} };
  Blocker = { walk = true; };
}
entity.register 'Goo' {
  name = 'goo';
  Render = { face = '≈'; colour = {0,255,0} };
  Blocker = { walk = true; };
}
entity.register 'Ice' {
  name = 'ice';
  Render = { face = '≈'; colour = {128,255,0} };
  Blocker = { walk = true; };
}
entity.register 'Lava' {
  name = 'lava';
  Render = { face = '≈'; colour = {255,64,0} };
  Blocker = { walk = true; };
}

entity.register 'Floor' {
  name = 'floor';
  Render = { face = '.' }
}

entity.register 'TestObject' {
  name = "test object";
  Render = { face = '?' };
}

entity.register 'Door' {
  name = 'door';
  Door = {};
  Render = { face='!'; colour = {0xFF,0x99,0x33} };
}
