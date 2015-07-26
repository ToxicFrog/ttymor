--
-- Default methods for individual nodes in the tree.
--

local Node = {}
Node.__index = Node

-- Render the entire line at (x,y), with the label indented appropriate to depth.
function Node:render(x, y)
  if self.focused then
    tty.style('v')
  end
  tty.put(x, y, (' '):rep(self._tree.w))
  tty.put(x+self._depth+1, y, self:label(self._tree.w - self._depth - 2))
  if self.focused then
    tty.style('V')
  end
end

-- Return the calculated width of the node's label.
function Node:width()
  return #self:label(self._tree.w)
end

-- Return the node's actual label. This includes the expanded/collapsed
-- indicator, if any.
-- Passed the width it has available to draw in, for things like right-aligned
-- labels to use.
-- Note that this may be called during setup to calculate the width of the tree.
-- In that case, it will be passed the calculated width so far of the tree, which
-- may be 0 -- so it should handle things gracefully when that happens.
function Node:label(width)
  if #self == 0 then
    return ' '..self.name
  elseif self.expanded then
    --return '⊟'..self.name
    return '-'..self.name
  else
    --return '⊞'..self.name
    return '+'..self.name
  end
end

-- The user has requested to expand this node.
-- TODO: if the node is already expanded, expand its children.
function Node:expand()
  if #self == 0 then return end
  self.expanded = true
  self._tree:refresh()
end

-- The user has requested to collapse this node. By default, collapses the node
-- if it's expanded, but if it's already collapsed, collapses its *parent*;
-- repeatedly hitting 'collapse' will eventually get you to the top level.
-- TODO: collapse the node's children as well as the node itself.
function Node:collapse(recursing)
  if #self > 0 and self.expanded then
    self.expanded = false
    if self:parent_of(self._tree:focused()) then
      self._tree:set_focus(self._index)
    end
    -- collapse children
    for i,node in ipairs(self) do
      node:collapse(true)
    end
    self._tree:refresh()
  elseif self._parent and not recursing then
    return self._parent:collapse()
  end
end

function Node:toggle()
  if self.expanded then
    return self:collapse()
  else
    return self:expand()
  end
end

function Node:activate()
  if #self > 0 then
    return self:toggle()
  else
    return self
  end
end

-- Returns true of the caller is a parent node of the argument.
function Node:parent_of(node)
  repeat
    if node == self then return true end
    node = node._parent
  until not node
  return false
end

return function(t)
  return setmetatable(t, Node)
end
