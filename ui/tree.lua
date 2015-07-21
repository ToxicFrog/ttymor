-- Default methods for individual nodes in the tree. --
local Node = {}
Node.__index = Node

-- Render the entire line at (x,y), with the label indented appropriate to depth.
function Node:render(x, y, depth)
  if self.focused then
    tty.style('v')
  end
  tty.put(x, y, (' '):rep(self.tree.w))
  tty.put(x+depth+1, y, self:label())
  if self.focused then
    tty.style('V')
  end
end

-- Return the calculated width of the node's label.
function Node:width()
  return #self:label()
end

-- Return the node's actual label. This includes the expanded/collapsed
-- indicator, if any.
function Node:label()
  if #self == 0 then
    return ' '..self.text
  elseif self.expanded then
    --return '⊟'..self.text
    return '-'..self.text
  else
    --return '⊞'..self.text
    return '+'..self.text
  end
end

-- The user has requested to expand this node.
-- TODO: if the node is already expanded, expand its children.
function Node:expand()
  if #self > 0 then
    self.expanded = true
  end
end

-- The user has requested to collapse this node. By default, collapses the node
-- if it's expanded, but if it's already collapsed, collapses its *parent*;
-- repeatedly hitting 'collapse' will eventually get you to the top level.
-- TODO: collapse the node's children as well as the node itself.
function Node:collapse()
  if #self > 0 and self.expanded then
    self.expanded = false
    if self:parent_of(self.tree.focused) then
      self.tree:set_focus(self)
    end
  elseif self.parent then
    return self.parent:collapse()
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

-- Default method implementations for the tree as a whole. --
local Tree = { w = 0; h = 0; focused = {}; }
Tree.__index = Tree

-- Focus the given node.
function Tree:set_focus(node)
  self.focused.focused = false
  self.focused = node
  node.focused = true
end

-- Select the previous visible node.
function Tree:focus_prev()
  self:set_focus(self.focused.prev)
end

-- Select the next visible node.
function Tree:focus_next()
  self:set_focus(self.focused.next)
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

-- Return the calculated height, in rows, of the tree when fully expanded. This
-- is == to the total number of nodes in the tree.
function Tree:height()
  local h = 0;
  for _ in self:walk() do h = h+1 end
  return h
end

-- Render the entire tree by drawing a titled box, then calling :render on each
-- visible node with appropriate coordinates passed in.
function Tree:render()
  local y = 1
  local h = self:height()

  ui.box(self.view, self.title)
  tty.pushwin(self.view)

  for node,depth in self:walk() do
    node:render(1, y, depth)
    y = y+1
  end

  tty.popwin()
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
  local node = self.focused

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

-- The user has chosen the focused node as the result of the tree UI.
function Tree:activate()
  return self.focused
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
  enter = 'activate';
  escape = 'cancel';
  quit = 'cancel';
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
  tree:set_focus(tree[1])
  if tree.title then
    tree.w = #tree.title
  end

  local stack = {}
  local last = {}
  for node,depth in tree:walk(true) do
    setmetatable(node, Node)
    stack[depth] = node
    node.tree = tree
    node.parent = stack[#stack-1]
    node.prev = last
    last.next = node
    last = node

    tree.h = tree.h+1
    tree.w = tree.w:max(node:width() + depth)
  end
  last.next = tree[1]
  tree[1].prev = last
  tree.w = tree.w+2

  tree.view = ui.centered(tree.w+2,tree.h+2)
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
