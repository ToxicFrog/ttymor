local Node = require 'ui.Node'
local Tree = require 'ui.Tree'

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
  tree = Tree(tree)
  tree.bindings = setmetatable(tree.bindings or {}, {__index = bindings})
  tree.w,tree.h = 0,0
  if tree.name then
    tree.w = #tree.name
  end

  local stack = {}
  for node,depth in tree:walk(true) do
    node = Node(node)
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
