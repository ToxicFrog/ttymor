-- CellTree is a subclass of Tree that displays the contents of one or more
-- cells, automatically refreshing the contents on render.
--
-- By default it passes all messages through to the focused element, but the
-- 'activate' message can be overridden, so that e.g. you can open a CellTree
-- where activating an entity sends 'pickup' or 'examine' rather than 'activate'.

local CellTree = ui.Tree:subclass {
  cells = {};
  empty = true;
  map = nil;
  filter = f' => true';
  activate_msg = 'cmd_activate';
}

function CellTree:__init(init)
  ui.Tree.__init(self, init)
  self:refreshCellContents()
end

function CellTree:refreshCellContents()
  self.content:clear()
  self.empty = true
  local tree = {}
  for _,cell in ipairs(self.cells) do
    for ent in self.map:contents(cell[1], cell[2]) do
      if self.filter(ent) then
        self.content:attach(ui.EntityLine { entity = ent })
        self.empty = false
      end
    end
  end
  ui.layout()
  self:buildFocusList()
  if self._focus then
    self:setFocus(self._focus)
  end
end

function CellTree:cmd_update()
  self:refreshCellContents()
  if self.empty then
    self:destroy()
  end
  return false
end

return CellTree
