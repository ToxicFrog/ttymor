local Tree = require 'ui.Tree'
local Node = require 'ui.Node'

local HudWin = Tree:subclass {
  position = 'fixed';
  readonly = true;
  visible = true;
  stack = nil;
  content = nil;
  colour = { 192, 192, 192 };
}

function HudWin:__init(...)
  Tree.__init(self, ...)
  self.stack = {}
end

-- Width and height of the HUD are fixed, so this is a no-op.
function HudWin:resize() end

function HudWin:setContent(data)
  self.content = data
  self.name = data.name
  self.root = Node(self, nil, {
    name = data.name;
    unpack(data);
  })
  self:refresh()
end

function HudWin:pushContent()
  table.insert(self.stack, self.content)
end

function HudWin:popContent()
  self:setContent(table.remove(self.stack))
end

return HudWin
