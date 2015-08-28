local Window = require 'ui.Window'
local Box = Window:subclass {}

function Box:render()
  ui.box(nil, self.name)
end

return Box
