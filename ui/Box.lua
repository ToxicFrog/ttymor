ui.Box = ui.Window:subclass {}

function ui.Box:render()
  ui.box(nil, self.name)
end
