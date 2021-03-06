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
  _focus = 1;
  _focus_list = {};
  margins = { up=1, dn=1, lf=2, rt=2 };
}

local function makeNode(data)
  if type(data) == 'string' then
    return ui.TextLine { text = data }
  elseif data.render then
    -- We make the possibly unwarranted assumption here that data is a subclass of Window
    return data
  elseif #data > 0 then
    for i,v in ipairs(data) do
      data[i] = makeNode(v)
    end
    return ui.Expander(data)
  else
    return ui.TextLine(data)
  end
end

function Tree:initFrom(init)
  self.content:clear()
  for i,v in ipairs(init) do
    self.content:attach(makeNode(v))
  end
  self:buildFocusList()
end

function Tree:__init(init)
  init.content = ui.VList {
    name = init.title .. '$internal_list';
  }
  ui.Box.__init(self, init)
  self:initFrom(self)
end

function Tree:postLayout()
  self:buildFocusList()
end

function Tree:buildFocusList()
  local function aux(win, list)
    if not win.visible then return list end
    if win.can_focus then table.insert(list, win) end
    if win.focused then self._focus = #list end
    for child in win:children() do aux(child, list) end
    return list
  end
  self._focus_list = aux(self.content, {})
  if #self._focus_list == 0 then
    self._focus = nil
  else
    self._focus = math.bound(self._focus or 1, 1, #self._focus_list)
  end
  if self._focus then
    self:setFocus(self._focus)
  end
end

function Tree:setFocus(index)
  if not self._focus then return end
  self:focused().focused = false
  self._focus = (index-1) % #self._focus_list + 1
  self:focused().focused = true
end

function Tree:focused()
  return self._focus_list[self._focus]
end

-- Select the previous visible node.
function Tree:cmd_up()
  if self._focus then
    self:setFocus(self._focus - 1)
    self:scroll_to_line(self._focus)
  else
    self:scroll_up()
  end
  return true
end

-- Select the next visible node.
function Tree:cmd_down()
  if self._focus then
    self:setFocus(self._focus + 1)
    self:scroll_to_line(self._focus)
  else
    self:scroll_down()
  end
  return true
end

function Tree:cmd_scrollup()
  if self._focus then
    self:setFocus((#self._focus_list):min(self._focus - (self.h/2):ceil()))
    self:scroll_to_line(self._focus)
  else
    self:page_up()
  end
  return true
end

function Tree:cmd_scrolldown()
  if self._focus then
    self:setFocus((0):max(self._focus + (self.h/2):ceil()))
    self:scroll_to_line(self._focus)
  else
    self:page_down()
  end
  return true
end

-- The user has declined to choose a node at all.
function Tree:cancel()
  self:destroy()
  return true
end

function Tree:cmd_cancel()
  self:cancel()
  return true
end

function Tree:cmd_update()
  return false
end

return Tree
