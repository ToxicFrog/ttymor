-- This file defines both the default controls, and the menu structure for the keybindings menu.
-- It does not have the same format as the saved keybindings file.
return {
  { name = "Movement";
    { name = "Up/North",    command = 'up';      keys = { 'W', 'up' } };
    { name = "Down/South",  command = 'down';    keys = { 'S', 'down' } };
    { name = 'Left/West',   command = 'left';    keys = { 'A', 'left' } };
    { name = 'Right/East',  command = 'right';   keys = { 'D', 'right' } };
    { name = 'Ascend';      command = 'ascend';  keys = { '<' } };
    { name = 'Descend';     command = 'descend'; keys = { '>' } };
  };
  { name = "UI";
    { name = 'Select/Activate'; command = 'activate'; keys = { 'enter' }};
    { name = 'Cancel';          command = 'cancel';   keys = { 'esc', '`' }};
    { name = 'Scroll Up';       command = 'scrollup'; keys = { 'pgup' }};
    { name = 'Scroll Down';     command = 'scrolldn'; keys = { 'pgdn' }};
  };
  { name = "Gameplay";
    { name = "Pick Up/Drop"; command = 'pickup';    keys = { ',' }};
    { name = "Inventory";    command = 'inventory'; keys = { 'I' }};
  };
}
