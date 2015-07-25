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


--
-- Default method implementations for the tree as a whole. --
--


local Tree = {
  w = 0; h = 0;
  _focused = 1;
  colour = { 255, 255, 255 };
}
Tree.__index = Tree

-- Focus the given node.
function Tree:set_focus(index)
  self:focused().focused = false
  self._focused = (index-1) % #self.nodes + 1
  self:focused().focused = true
end

function Tree:focused()
  assert(#self.nodes >= self._focused, "focus %d exceeds internal node list %d", self._focused, #self.nodes)
  return self.nodes[self._focused]
end

-- Select the previous visible node.
function Tree:focus_prev()
  self:set_focus(self._focused - 1)
  self:scroll_to_focused()
end

-- Select the next visible node.
function Tree:focus_next()
  self:set_focus(self._focused + 1)
  self:scroll_to_focused()
end

function Tree:scroll_up()
  self:set_focus(self._focused - (self.h/2):ceil())
  self:scroll_to_focused()
end

function Tree:scroll_down()
  self:set_focus(self._focused + (self.h/2):ceil())
  self:scroll_to_focused()
end

-- Scroll so that the focused element is in the center of the screen, or close to.
function Tree:scroll_to_focused()
  if not self.max_h then return end
  self.scroll = math.bound(0, self._focused - self.h/2, self.max_h - self.h):floor()
end

-- Return a DFS iterator over all nodes in the tree; yields (node,depth) for
-- each node. The top level has depth 0, not 1.
function Tree:walk(include_collapsed)
  local function dfs_walk(tree, depth)
    for _,subtree in ipairs(tree) do
      coroutine.yield(subtree, depth)
      if subtree.expanded or include_collapsed then
        dfs_walk(subtree, depth+1)
      end
    end
  end
  return coroutine.wrap(dfs_walk),self,0
end

-- Render the entire tree by drawing a titled box, then calling :render on each
-- visible node with appropriate coordinates passed in.
function Tree:render()
  tty.colour(unpack(self.colour))
  tty.pushwin(self.view)
  ui.box(nil, self.name)
  local scroll = self.scroll or 0

  if self.scroll then
    -- render scrollbar
    ui.clear({ x=self.view.w-1; y=1; w=1; h=self.view.h-2 }, '┊')
    tty.put(self.view.w-1, 1, '┻')
    tty.put(self.view.w-1, self.view.h-2, '┳')
    local sb_distance = (self.scroll/(self.max_h - self.h)*(self.h - 2 - self.scroll_height)):floor()
    ui.clear({ x=self.view.w-1; y=2+sb_distance; w=1; h=self.scroll_height }, '▓') --█
  end

  for y=1,self.h:min(#self.nodes) do
    self.nodes[y+scroll]:render(1, y)
  end

  tty.popwin()
end

-- Set up the next/prev links
function Tree:refresh()
  self.nodes = {}
  for node in self:walk() do
    table.insert(self.nodes, node)
    node._index = #self.nodes
    if node.focused then
      self._focused = node._index
    end
  end
end

-- Call an event handler appropriate for a given input event.
-- The search works thus:
-- If there is no self.bindings entry for the event, it is ignored entirely.
-- If the entry is a function, it's called and passed self.
-- If the entry is a string, and the focused node has a method with that name,
-- the method is called.
-- If it's a string and the tree has a method with that name, it's called.
-- In all of the previous three cases, if the function called returns a value,
-- that value is returned.
-- If none of the above cases apply, an error is raised.
function Tree:call_handler(key)
  key = self.bindings[key]
  if not key then return end
  local node = self:focused()

  if type(key) == 'function' then
    return key(self)
  elseif type(node[key]) == 'function' then
    return node[key](node)
  elseif type(self[key]) == 'function' then
    return self[key](self)
  else
    return error("no handler in tree for %s -- wanted function, got %s (node) and %s (tree)" % {
        name, type(node[key]), type(self[key])})
  end
end

-- The user has declined to choose a node at all.
function Tree:cancel()
  return false
end

-- Run the tree UI loop. Repeatedly render the tree, get input, and call the
-- handler, if any, for that input event. As soon as a handler returns a non-
-- nil value, break out of the loop and return that value.
function Tree:run()
  local R
  repeat
    self:render()
    R = self:call_handler(ui.readkey())
  until R ~= nil
  ui.clear(self.view)
  return R
end

-- Default command bindings for tree mode.
-- This lets you navigate with the directional keys, choose a node (exiting tree
-- mode and returning that node) with enter, and cancel (exiting tree mode and
-- returning false) with cancel.
local bindings = {
  up = 'focus_prev';
  down = 'focus_next';
  left = 'collapse';
  right = 'expand';
  activate = 'activate';
  cancel = 'cancel';
  scrollup = 'scroll_up';
  scrolldn = 'scroll_down';
}

-- Turn a mere tree of tables into a Tree.
-- This consists of installing the default methods for Tree on the top level,
-- and for Node on all its children; installing the default bindings; setting
-- the first top-level child as the focused node; setting up the next, previous,
-- parent, and tree links; and computing the width and height of the box needed
-- to display the fully expanded tree.
local function setup_tree(tree)
  setmetatable(tree, Tree)
  tree.bindings = setmetatable(tree.bindings or {}, {__index = bindings})
  tree.w,tree.h = 0,0
  if tree.name then
    tree.w = #tree.name
  end

  local stack = {}
  for node,depth in tree:walk(true) do
    setmetatable(node, Node)
    node._tree = tree
    node._parent = stack[depth]
    node._depth = depth
    stack[depth+1] = node

    tree.h = tree.h+1
    tree.w = tree.w:max(node:width() + depth)
  end

  tree.w = tree.w+2
  tree.view = ui.centered(tree.w+2,tree.h+2)
  if tree.w > tree.view.w-2 then
    tree.max_w,tree.w = tree.w,tree.view.w-2
  end
  if tree.h > tree.view.h-2 then
    tree.max_h,tree.h = tree.h,tree.view.h-2
    tree.scroll = 0
    tree.scroll_height = (tree.h/tree.max_h*tree.view.h-2):ceil()
  end
  tree:refresh()
  tree:set_focus(1)
  return tree
end

-- External API functions. --

-- Turn a tree into a Tree and activate it, running until one of the handlers
-- returns a value.
function ui.tree(tree)
  return setup_tree(tree):run()
end

-- Turn a tree into a Tree and return it without running it.
function ui.Tree(tree)
  return setup_tree(tree)
end
