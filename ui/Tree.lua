-- Tree is a UI abstraction for making heirarchical menus.
--
-- Tree is actually a subclass of Box (for the frame and scrolling);
-- the content is handled by a List. On creation, the Tree walks its
-- contents and wraps each one in a Node, which supplies default
-- handlers for things like expansion/contraction. The tree has a
-- method, :refresh(), which walks this internal tree of Nodes and
-- generates a list of the visible ones, populating the List that
-- is its sole child and handles actually rendering the content.

local Tree = ui.Box:subclass {
  _focused = 0
}
local Node = require 'ui.Node'

function Tree:__init(data)
  local nodes = {}
  for i,v in ipairs(data) do
    nodes[i] = v
    data[i] = nil
  end
  data.content = nil
  data.root = nil

  self.content = ui.List {
    name = data.name .. '$internal_list';
    visible = true;
    x = 1; y = 1; position = 'fixed';
  }
  self.root = Node(self, nil, {
    name = data.name .. '$root';
    unpack(nodes);
  })
  ui.Window.__init(self, data)
end

-- Recalculate the width and height for the tree based on its contents.
function Tree:resize(w, h)
  local tree_w,tree_h = 0,0
  self.root:size()

  tree_w = self.root.w
  tree_h = self.root.h - 1  -- the root node counts itself in the size, but doesn't take up a row on screen
  if self.name then
    tree_w = tree_w:max(#self.name)
  end

  self.w = w:min(tree_w+2)
  self.h = h:min(tree_h+2)

  return self.w-2,self.h-2
end

function Tree:reposition(...)
  ui.Box.reposition(self, ...)
  self:refresh()
  if self._focused == 0 then
    self:set_focus(1)
  end
end

-- Focus the given node.
function Tree:set_focus(index)
  if self:focused() then
    self:focused().focused = false
  end
  self._focused = (index-1) % self.content:len() + 1
  local node = self:focused()
  node.focused = true
  if node.help then
    ui.setHUD(node.name, node.help)
  else
    ui.setHUD(nil)
  end
end

function Tree:focused()
  assertf(self.content:len() >= self._focused, "focus %d exceeds internal node list %d",
      self._focused, self.content:len())
  return self.content.content[self._focused]
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
  self:set_focus(self._focused - (self.content.h/2):ceil())
  self:scroll_to_focused()
end

function Tree:focus_page_down()
  self:set_focus(self._focused + (self.content.h/2):ceil())
  self:scroll_to_focused()
end

-- Scroll so that the focused element is in the center of the screen, or close to.
function Tree:scroll_to_focused()
  self.content:scroll_to_index(self._focused)
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
  return coroutine.wrap(dfs_walk),self.root,0
end

-- Build the list of displayable nodes. Called when the list changes due to nodes
-- being expanded or collapsed.
function Tree:refresh()
  self.content:clear()
  for node in self:walk() do
    self.content:add(node)
    node.index = self.content:len()
    if node.focused then
      self._focused = node.index
    end
  end
end

-- The user has declined to choose a node at all.
function Tree:cancel()
  ui.popHUD()
  self:destroy()
  return true
end

function Tree:cmd_up()
  self:focus_prev()
  return true
end

function Tree:cmd_down()
  self:focus_next()
  return true
end

function Tree:cmd_left()
  self:focused():collapse()
  return true
end

function Tree:cmd_right()
  self:focused():expand()
  return true
end

function Tree:cmd_activate()
  self:focused():activate()
  return true
end

function Tree:cmd_cancel()
  self:cancel()
  return true
end

function Tree:cmd_scrollup()
  self:focus_page_up()
  return true
end

function Tree:cmd_scrolldn()
  self:focus_page_down()
  return true
end

return Tree
