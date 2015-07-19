local function dfs(tree)
  local function dfs_walk(tree, depth)
    for _,subtree in ipairs(tree) do
      coroutine.yield(subtree, depth)
      dfs_walk(subtree, depth+1)
    end
  end
  return coroutine.wrap(dfs_walk),tree,0
end

function ui.tree(tree)
  for subtree, depth in dfs(tree) do
    io.write("\r\n"..("  "):rep(depth)..subtree.text)
  end
  do return end
end
