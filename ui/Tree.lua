--
-- Default method implementations for the tree as a whole. --
--
local Tree = ui.Window:subclass {
  -- *displayable* text width and height.
  text_w = 0; text_h = 0;
  -- Number of lines scrolled down.
  scroll = 0;
  -- Line under focus.
  _focused = 1;
  colour = { 255, 255, 255 };
}
ui.Tree = Tree

function Tree:__index(k)
  if rawget(self, '_ptr') and self._ptr[k] ~= nil then
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
  self:set_focus(self._focused - (self.text_h:min(self.rows)/2):ceil())
  self:scroll_to_focused()
end

function Tree:focus_page_down()
  self:set_focus(self._focused + (self.text_h:min(self.rows)/2):ceil())
  self:scroll_to_focused()
end

-- scroll up/down the given number of lines, without wrapping or changing focus
function Tree:scroll_by(n)
  self.scroll = math.bound(0, self.scroll+n, self.rows - self.text_h):floor()
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
  self:scroll_by(-self.text_h:min(self.rows)/2)
end
function Tree:page_down()
  self:scroll_by(self.text_h:min(self.rows)/2)
end

-- Scroll so that the focused element is in the center of the screen, or close to.
function Tree:scroll_to_focused()
  self.scroll = math.bound(0, self._focused - self.text_h/2, self.rows - self.text_h):floor()
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
  ui.box(nil, self.name)

  if self.scrollable then
    -- render scrollbar
    ui.clear({ x=self.w-1; y=1; w=1; h=self.text_h }, '┊')
    tty.put(self.w-1, 1, '┻')
    tty.put(self.w-1, self.text_h, '┳')
    local sb_distance = (self.scroll/(self.rows - self.text_h)*(self.text_h - 2 - self.scroll_height)):floor()
    ui.clear({ x=self.w-1; y=2+sb_distance; w=1; h=self.scroll_height }, '▓') --█
  end

  for y=1,self.text_h:min(self.rows) do
    -- assertf(self.nodes[y+scroll], "scroll error: y=%d h=%d mh=%d scroll=%d #nodes=%d",
    --     y, self.text_h, self.max_h or 0, scroll, #self.nodes)
    self.nodes[y+self.scroll]:render(1, y)
  end
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
  if self.rows > self.text_h then
    self.scrollable = true
    self.scroll_height = (self.text_h/self.rows*(self.text_h-2)):ceil()
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
  self:show()
  local R
  log.debug('entering tree loop')
  repeat
    R = self:call_handler(ui.readkey())
  until R ~= nil
  log.debug('leaving tree loop, destroying tree')
  self:destroy()
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
function Tree:__init(data)
  self._ptr = data
  self.parent = data.parent or ui.main_win

  if self.name then
    self.text_w = #self.name
  end

  local function convert_tree(node, depth)
    for i,child in ipairs(node._ptr) do
      if type(child) == 'string' then
        child = { name = child }
      end
      child = Node(child)
      child._tree = self
      child._parent = node
      child._depth = depth
      rawset(node, i, child)
      self.text_h = self.text_h+1
      self.text_w = self.text_w:max(node[i]:width()+depth)
      convert_tree(child, depth+1)
    end
  end

  convert_tree(self, 0)
  for _,node in ipairs(self) do node._parent = nil end

  -- self.w and self.h are the actual on-screen display size; text_w and text_h
  -- are the max displayable width and height, i.e. w,h excluding
  -- decorations. There's a separate field, rows, for number of actual lines of
  -- text in visible nodes; if rows > text_h, the tree is scrollable.
  -- We add 4 to text_w here because we want space for margins, and then only
  -- subtract 2 later on because the margins are included in the text_w.
  self.w = self.text_w+4
  self.h = self.text_h+2

  self:refresh()

  if self.readonly then
    self.bindings = setmetatable(self.bindings or {}, {__index = readonly_bindings})
  else
    self.bindings = setmetatable(self.bindings or {}, {__index = bindings})
    self:set_focus(1)
  end

  -- We call the superclass ctor at the end here, since it's only at the end that
  -- we know our desired width and height.
  ui.Window.__init(self, {})

  -- Doing so may have caused the *actual* width and height to change because we
  -- asked for more than was available, so take that into account.
  self.text_w = self.w-2
  self.text_h = self.h-2
end

return Tree
