local Node = {}
Node.__index = Node

function Node:render(x, y)
  if self.selected then
    -- tty.style('B')
    tty.put(x-1, y, '*')
    -- tty.style('b')
  end
  if #self == 0 then
    tty.put(x+1, y, self.text)
  elseif self.expanded then
    tty.put(x, y, '⊟'..self.text)
  else
    tty.put(x, y, '⊞'..self.text)
  end
end

function Node:expand()
  if #self > 0 then
    self.expanded = true
  end
end

function Node:collapse()
  if #self > 0 and self.expanded then
    self.expanded = false
    if self:parent_of(self.tree.selected) then
      self.tree:select(self)
    end
  elseif self.parent then
    return self.parent:collapse()
  end
end

function Node:select()
  return self
end

function Node:cancel()
  return false
end

function Node:parent_of(node)
  repeat
    if node == self then return true end
    node = node.parent
  until not node
  return false
end

local Tree = { w = 0; h = 0; max_h = 0; }
Tree.__index = Tree

function Tree:select(node)
  self.selected.selected = false
  self.selected = node
  node.selected = true
end

function Tree:select_prev()
  self:select(self.selected.prev)
end

function Tree:select_next()
  self:select(self.selected.next)
end

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

function Tree:height()
  local h = 0;
  for _ in self:walk() do h = h+1 end
  return h
end

function Tree:render()
  local y = 1
  local h = self:height()

  ui.box(self.view)
  tty.pushwin(self.view)

  for node,depth in self:walk() do
    node:render(2+depth, y)
    y = y+1
  end

  tty.popwin()
end

function Tree:call_handler(node, key)
  key = self.bindings[key]
  if not key then return end

  if type(key) == 'function' then
    return key(self, node)
  elseif type(node[key]) == 'function' then
    return node[key](node, self)
  elseif type(self[key]) == 'function' then
    return self[key](self, node)
  else
    return error("no handler in tree for %s -- wanted function, got %s (node) and %s (tree)" % {
        name, type(node[key]), type(self[key])})
  end
end

function Tree:run()
  repeat
    self:render()
    local R = self:call_handler(self.selected, ui.readkey())
  until R ~= nil
end

local bindings = {
  up = 'select_prev';
  down = 'select_next';
  left = 'collapse';
  right = 'expand';
  enter = 'select';
  escape = 'cancel';
  quit = 'cancel';
}

local function setup_tree(tree)
  setmetatable(tree, Tree)
  tree.bindings = setmetatable(tree.bindings or {}, {__index = bindings})
  tree.selected = tree[1]
  tree[1].selected = true

  local stack = {}
  local last = {}
  for node,depth in tree:walk(true) do
    tree.h = tree.h+1
    tree.w = tree.w:max(#node.text + depth + 1)
    setmetatable(node, Node)
    stack[depth] = node
    node.tree = tree
    node.parent = stack[#stack-1]
    node.prev = last
    last.next = node
    last = node
  end
  last.next = tree[1]
  tree[1].prev = last

  tree.view = ui.centered(tree.w+4,tree.h+2)
  return tree
end

function ui.tree(tree)
  return setup_tree(tree):run()
end

function ui.Tree(tree)
  return setup_tree(tree)
end
