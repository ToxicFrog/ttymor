--
-- Default method implementations for the tree as a whole. --
--
local Window = require 'ui.Window'
local Node = require 'ui.Node'

local Tree = Window:subclass {
  -- *displayable* text width and height.
  text_w = 0; text_h = 0;
  -- Number of lines scrolled down.
  scroll = 0;
  -- Line under focus.
  _focused = 1;
  colour = { 255, 255, 255 };
}

-- Focus the given node.
function Tree:set_focus(index)
  self:focused().focused = false
  self._focused = (index-1) % #self.nodes + 1
  local node = self:focused()
  node.focused = true
  if node.help then
    ui.setHUD(node.name, node.help)
  else
    ui.setHUD(nil)
  end
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
  self.scroll = math.bound(self.scroll+n, 0, self.rows - self.text_h):floor()
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
  self.scroll = math.bound(self._focused - self.text_h/2, 0, self.rows - self.text_h):floor()
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

-- Render the entire tree by drawing a titled box, then calling :renderLabel on each
-- visible node with appropriate coordinates passed in.
function Tree:render()
  tty.colour(unpack(self.colour))
  ui.box(nil, self.name)

  if self.scrollable then
    local h = self.text_h
    local lines = self.rows
    local sb_height = ((h/lines) * (h-2)):floor():bound(1, self.h-4)
    local sb_distance = (self.scroll / (lines-h)
        * (h - 2 - sb_height)):floor():bound(0, self.h-4-sb_height)

    ui.clear({ x=self.w-1; y=2; w=1; h=self.h-4 }, '┊')
    tty.put(self.w-1, 1, '┻')
    tty.put(self.w-1, self.h-2, '┳')
    ui.clear({ x=self.w-1; y=2+sb_distance; w=1; h=sb_height }, '▓') --█
  end

  for y=1,self.text_h:min(self.rows) do
    -- assertf(self.nodes[y+scroll], "scroll error: y=%d h=%d mh=%d scroll=%d #nodes=%d",
    --     y, self.text_h, self.max_h or 0, scroll, #self.nodes)
    self.nodes[y+self.scroll]:renderLabel(1, y)
  end
end

-- Build the list of displayable nodes. Called when the list changes due to nodes
-- being expanded or collapsed.
function Tree:refresh()
  self.nodes = {}
  for node in self:walk() do
    table.insert(self.nodes, node)
    node.index = #self.nodes
    if node.focused then
      self._focused = node.index
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

-- The user has declined to choose a node at all.
function Tree:cancel()
  self:destroy()
end

-- Recalculate the width and height for the tree.
-- Overrides Window:resize.
function Tree:resize()
  self.root:size()

  if self.name then
    self.text_w = #self.name
  end

  self.text_w = self.text_w:max(self.root.w)
  self.text_h = self.root.h - 1  -- the root node itself has no height

  -- self.w and self.h are the actual on-screen display size; text_w and text_h
  -- are the max displayable width and height, i.e. w,h excluding
  -- decorations. There's a separate field, rows, for number of actual lines of
  -- text in visible nodes; if rows > text_h, the tree is scrollable.
  -- We add 4 to text_w here because we want space for margins, and then only
  -- subtract 2 later on because the margins are included in the text_w.
  self.w = self.text_w+4
  self.h = self.text_h+2
end

-- Override for Window:reposition() so that we set text_w and text_h appropriately
-- after potentially being resized.
function Tree:reposition()
  Window.reposition(self)
  self.text_w = self.w - 2
  self.text_h = self.h - 2
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

function Tree:__init(data)
  Window.__init(self, data)
  self.root = Node(self, nil, {
    name = data.name;
    unpack(data);
  })

  if self.readonly then
    self.bindings = setmetatable(self.bindings or {}, {__index = readonly_bindings})
  else
    self.bindings = setmetatable(self.bindings or {}, {__index = bindings})
  end
  self:refresh()
end

return Tree
