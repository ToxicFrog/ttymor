local function dfs(tree)
  local function dfs_walk(tree, depth)
    for _,subtree in ipairs(tree) do
      coroutine.yield(subtree, depth)
      if subtree.expanded then
        dfs_walk(subtree, depth+1)
      end
    end
  end
  return coroutine.wrap(dfs_walk),tree,0
end

local function render_node(node, x, y, selected)
  if node.render then
    return node:render(x,y,selected)
  end
  if selected then
    -- tty.style('B')
    tty.put(x-1, y, '*')
    -- tty.style('b')
  end
  if #node == 0 then
    tty.put(x+1, y, node.text)
  elseif node.expanded then
    tty.put(x, y, '⊟'..node.text)
  else
    tty.put(x, y, '⊞'..node.text)
  end
end

local function setup_tree(tree, selected)
  local w,h = 0,0
  tree.selected = tree.selected or 1
  for node,depth in dfs(tree) do
    h = h+1
    w = w:max(#node.text + depth + 1)
  end
  return w,h
end

local function render_tree(tree, w, h, selected)
  local selected_node = nil
  local y = 1
  for node,depth in dfs(tree) do
    if y == selected then
      render_node(node, 2+depth, y, true)
      selected_node = node
    else
      render_node(node, 2+depth, y, false)
    end
    y = y+1
  end
  return selected_node
end

function ui.tree(tree, selected)
  local w,h = setup_tree(tree)
  local view = ui.centered(w+4,h+2)
  local selected_node = nil

  if not selected or selected < 1 or selected > h then
    selected = 1
  end

  while true do
    ui.box(view)
    tty.pushwin(view)
    selected_node = render_tree(tree, w, h, selected)
    tty.popwin()

    local key = ui.readkey()
    if key == 'down' then
      selected = selected % h + 1
    elseif key == 'up' then
      -- dec selected
      selected = (selected - 2) % h + 1
    elseif key == 'left' then
      -- collapse
      if #selected_node > 0 then
        selected_node.expanded = false
        return ui.tree(tree, selected)
      end
    elseif key == 'right' then
      -- expand
      if #selected_node > 0 then
        selected_node.expanded = true
        return ui.tree(tree, selected)
      end
    elseif key == 'enter' then
      return selected_node
    else
      print(key)
      ui.readkey()
    end
  end
end
