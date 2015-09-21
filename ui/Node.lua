-- A single node in a Tree.
local Node = Object:subclass {
  expanded = false;
  focused = false;
  w = 0; h = 1;
  depth = 0;
}

function Node:__init(tree, parent, data)
  if type(data) == 'string' then
    data = {
      text = data;
    }
  end
  Object.__init(self, data)
  assert(self.name, "All TreeNodes are required to have a name")
  for k,v in pairs(data) do
    assert(v == self[k])
  end
  self.depth = parent and parent.depth + 1 or 0
  self.tree = tree
  self.parent = parent

  for i,v in ipairs(self) do
    self[i] = getmetafield(self, '__class')(tree, self, v)
  end
end

function Node:addNode(data)
  table.insert(self, Node(self.tree, self, data))
end

-- Calculate width and height of this node.
function Node:size()
  self.w = #self:label(0) + self.depth
  self.h = 1

  for i,child in ipairs(self) do
    local w,h = child:size()
    self.w = self.w:max(w)
    self.h = self.h + h
  end

  return self.w,self.h
end

-- Render the entire line at (x,y), with the label indented appropriate to depth.
function Node:renderLabel(x, y)
  if self.focused then
    tty.style('v')
  end
  tty.put(x, y, (' '):rep(self.tree.list.w))
  tty.put(x+self.depth, y, self:label(self.tree.list.w - self.depth))
  if self.focused then
    tty.style('V')
  end
end

-- Return the node's actual label. This includes the expanded/collapsed
-- indicator, if any.
-- Passed the width it has available to draw in, for things like right-aligned
-- labels to use.
-- Note that this function is called during initialization for width calculation,
-- at which point the current width is 0. It should handle this gracefully.
function Node:label(width)
  if #self == 0 then
    return self.name
  elseif self.expanded then
    --return '⊟'..self.name
    return '[-] '..self.name
  else
    --return '⊞'..self.name
    return '[+] '..self.name
  end
end

-- The user has requested to expand this node.
-- TODO: if the node is already expanded, expand its children.
function Node:expand()
  if #self == 0 then return end
  self.expanded = true
  self.tree:refresh()
end

-- The user has requested to collapse this node. By default, collapses the node
-- if it's expanded, but if it's already collapsed, collapses its *parent*;
-- repeatedly hitting 'collapse' will eventually get you to the top level.
-- TODO: collapse the node's children as well as the node itself.
function Node:collapse(recursing)
  if #self > 0 and self.expanded then
    self.expanded = false
    if self:parent_of(self.tree:focused()) then
      self.tree:set_focus(self.index)
    end
    -- collapse children
    for i,node in ipairs(self) do
      node:collapse(true)
    end
    self.tree:refresh()
  elseif self.parent and not recursing then
    return self.parent:collapse()
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
    -- HACK HACK HACK
    -- The old Tree/Node API assumed that returning anything from a handler
    -- meant the tree should destroy itself. This was the default behaviour of
    -- activate.
    -- I'm hacking in similar behaviour here to get the menus working post-keyinput
    -- rewrite. TODO: remove this during the Tree rewrite.
    return self.tree:cancel()
  end
end

-- Returns true of the caller is a parent node of the argument.
function Node:parent_of(node)
  repeat
    if node == self then return true end
    node = node.parent
  until not node
  return false
end

return Node
