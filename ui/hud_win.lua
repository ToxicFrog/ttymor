local Tree = require 'ui.Tree'
local Node = require 'ui.Node'

local HudWin = Tree:subclass {
  position = 'fixed';
  readonly = true;
  visible = true;
}

-- Width and height of the HUD are fixed, so this is a no-op.
function HudWin:resize() end

function HudWin:setContent(name, data)
  self.name = name
  self.root = Node(self, nil, {
    name = name;
    unpack(data);
  })
  self:refresh()
end

return HudWin
