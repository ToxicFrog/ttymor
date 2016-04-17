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
  size = { 0, 0 };
  position = { 0, 0 };
}
local Node = require 'ui.Node'

function Tree:__init(init)
  init.content = ui.VList {
    name = init.title .. '$internal_list';
  }
  ui.Box.__init(self, init)

  for i,v in ipairs(self) do
    if type(v) == 'string' then
      self.content:attach(ui.TextLine { text = v })
    elseif #v > 0 then
      -- FIXME: attach expander
      self.content:attach(ui.TextLine(v))
    else
      self.content:attach(ui.TextLine(v))
    end
    self[i] = nil
  end
end

function Tree:getMargins()
  return 1,1,2,2
end

function Tree:layout(w, h)
  ui.Window.layout(self, w, h)
  self:buildFocusList()
end

function Tree:buildFocusList()
  local function aux(win, list)
    if not win.visible then return list end
    if win.activate then table.insert(list, win) end
    if win.focused then self._focus = #list end
    for child in win:children() do aux(child, list) end
    return list
  end
  self._focus_list = aux(self.content, {})
end

function Tree:setFocus(index)
  self:focused().focused = false
  self._focus = (index-1) % #self._focus_list + 1
  self:focused().focused = true
end

function Tree:focused()
  return self._focus_list[self._focus]
end

-- Select the previous visible node.
function Tree:cmd_up()
  self:setFocus(self._focus - 1)
  self:scroll_to_line(self._focus)
  return true
end

-- Select the next visible node.
function Tree:cmd_down()
  self:setFocus(self._focus + 1)
  self:scroll_to_line(self._focus)
  return true
end

function Tree:cmd_scrollup()
  self:setFocus((#self._focus_list):min(self._focus - (self.h/2):ceil()))
  self:scroll_to_line(self._focus)
  return true
end

function Tree:cmd_scrolldown()
  self:set_focus((0):max(self._focus + (self.h/2):ceil()))
  self:scroll_to_line(self._focus)
  return true
end

-- The user has declined to choose a node at all.
function Tree:cancel()
  ui.popHUD()
  self:destroy()
  return true
end

function Tree:cmd_activate()
  self:focused():activate(self)
  return true
end

function Tree:cmd_cancel()
  self:cancel()
  return true
end

return Tree
