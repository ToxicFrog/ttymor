--
-- Default method implementations for the tree as a whole. --
--


local Tree = {
  w = 0; h = 0;
  _focused = 1;
  colour = { 255, 255, 255 };
}

function Tree:__index(k)
  if self._ptr[k] ~= nil then
    return self._ptr[k]
  end
  return Tree[k]
end

-- Focus the given node.
function Tree:set_focus(index)
  self:focused().focused = false
  self._focused = (index-1) % #self.nodes + 1
  self:focused().focused = true
end

function Tree:focused()
  assertf(#self.nodes >= self._focused, "focus %d exceeds internal node list %d",
      self._focused, #self.nodes)
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

function Tree:focus_page_up()
  self:set_focus(self._focused - (self.h:min(self.rows)/2):ceil())
  self:scroll_to_focused()
end

function Tree:focus_page_down()
  self:set_focus(self._focused + (self.h:min(self.rows)/2):ceil())
  self:scroll_to_focused()
end

-- scroll up/down the given number of lines, without wrapping or changing focus
function Tree:scroll_by(n)
  self.scroll = math.bound(0, self.scroll+n, self.rows - self.h):floor()
end

-- Scroll up/down one line without wrapping or changing focus.
function Tree:scroll_up()
  self:scroll_by(-1)
end
function Tree:scroll_down()
  self:scroll_by(1)
end
-- Scroll up/down one half screen without wrapping or changing focus.
function Tree:page_up()
  self:scroll_by(-self.h:min(self.rows)/2)
end
function Tree:page_down()
  self:scroll_by(self.h:min(self.rows)/2)
end

-- Scroll so that the focused element is in the center of the screen, or close to.
function Tree:scroll_to_focused()
  self.scroll = math.bound(0, self._focused - self.h/2, self.rows - self.h):floor()
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

  if self.scrollable then
    -- render scrollbar
    ui.clear({ x=self.view.w-1; y=1; w=1; h=self.h }, '┊')
    tty.put(self.view.w-1, 1, '┻')
    tty.put(self.view.w-1, self.h, '┳')
    local sb_distance = (self.scroll/(self.rows - self.h)*(self.h - 2 - self.scroll_height)):floor()
    ui.clear({ x=self.view.w-1; y=2+sb_distance; w=1; h=self.scroll_height }, '▓') --█
  end

  for y=1,self.h:min(self.rows) do
    -- assertf(self.nodes[y+scroll], "scroll error: y=%d h=%d mh=%d scroll=%d #nodes=%d",
    --     y, self.h, self.max_h or 0, scroll, #self.nodes)
    self.nodes[y+self.scroll]:render(1, y)
  end

  tty.popwin()
end

-- Build the list of displayable nodes. Called when the list changes due to nodes
-- being expanded or collapsed.
function Tree:refresh()
  self.nodes = {}
  for node in self:walk() do
    table.insert(self.nodes, node)
    node._index = #self.nodes
    if node.focused then
      self._focused = node._index
    end
  end
  self.rows = #self.nodes
  if self.rows > self.h then
    self.scrollable = true
    self.scroll_height = (self.h/self.rows*(self.h-2)):ceil()
  else
    self.scrollable = false
    self.scroll = 0
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
    return errorf("no handler in tree for %s -- wanted function, got %s (node) and %s (tree)",
        key, type(node[key]), type(self[key]))
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

local Node = require 'ui.Node'

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
  scrollup = 'focus_page_up';
  scrolldn = 'focus_page_down';
}

local readonly_bindings = {
  up = 'scroll_up';
  down = 'scroll_down';
  activate = 'cancel';
  cancel = 'cancel';
  scrollup = 'page_up';
  scrolldn = 'page_down';
}

-- Turn a mere tree of tables into a Tree.
-- This consists of installing the default methods for Tree on the top level,
-- and for Node on all its children; installing the default bindings; setting
-- the first top-level child as the focused node; setting up the next, previous,
-- parent, and tree links; and computing the width and height of the box needed
-- to display the fully expanded tree.
return function(tree)
  tree = setmetatable({ _ptr = tree }, Tree)
  tree.w,tree.h,tree.scroll = 0,0,0
  if tree.name then
    tree.w = #tree.name
  end

  local function convert_tree(node, depth)
    for i,child in ipairs(node._ptr) do
      if type(child) == 'string' then
        child = { name = child }
      end
      child = Node(child)
      child._tree = tree
      child._parent = node
      child._depth = depth
      rawset(node, i, child)
      tree.h = tree.h+1
      tree.w = tree.w:max(node[i]:width()+depth)
      convert_tree(child, depth+1)
    end
  end

  convert_tree(tree, 0)
  for _,node in ipairs(tree) do node._parent = nil end

  -- tree.w and tree.h are the *displayable* width and height of the tree.
  -- w is equal to 2 (margins) + the total width (indent + text) of the widest node
  -- h is equal to the number of nodes in the tree
  -- Both, however, are capped at what will fit on the screen; furthermore, w cannot
  -- be any less than the minimum needed to display the title.
  -- There is a separate field, tree.rows, updated by tree:refresh(), for the total
  -- number of rows currently being viewed. If it exceeds tree.h, scrolling is
  -- enabled.
  tree.w = tree.w+2
  tree.view = ui.centered(tree.w+2,tree.h+2)
  tree.w = tree.w:min(tree.view.w-2)
  tree.h = tree.h:min(tree.view.h-2)

  tree:refresh()

  if tree.readonly then
    tree.bindings = setmetatable(tree.bindings or {}, {__index = readonly_bindings})
  else
    tree.bindings = setmetatable(tree.bindings or {}, {__index = bindings})
    tree:set_focus(1)
  end

  return tree
end

-- External API functions. --


