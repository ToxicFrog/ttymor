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
        name, type(node[key]), type(self[key]))
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

return function(t)
  return setmetatable(t, Tree)
end
