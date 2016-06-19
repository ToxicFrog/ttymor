local Window = Object:subclass {
  visible = true;
  position = { 0, 0 };
  size = { 0, 0 };
  margins = { up=0, dn=0, lf=0, rt=0 };
}

flags.register 'ui-perf' {
  default = false;
  help = 'Log detailed rendering performance info.';
}

function Window:__init(...)
  Object.__init(self, ...)
  self._children = {}
end

function Window:__tostring()
  return 'Window[%s]' % self.name
end

-- Returns an iterator over all visible children of the window. This means that
-- e.g. rendering and layout automatically skip invisible windows.
function Window:children()
  return coroutine.wrap(function()
    for _,child in ipairs(self._children) do
      if child.visible then
        coroutine.yield(child)
      end
    end
  end)
end

-- Perform window layout/sizing.
-- This is a two-pass approach.
-- The first pass (contract) is bottom up (children before parents). Each widget
-- sets its size to the smallest size possible. For fixed-size widgets, this is
-- that size; for containers, the smallest size that encompasses all of its
-- children + margins.
-- The second pass (expand) is top down. Widgets with fixed sizing or min-sizing
-- do nothing. Widgets with max-sizing or relative sizing adopt the size of their
-- parents.
function Window:layout(bb)
  bb = bb or { x=0; y=0; w=self.parent.w; h=self.parent.h; }
  self:layoutContract()
  self:layoutExpand(bb)
end

function Window:layoutContract()
  for child in self:children() do
    child:layoutContract()
  end
  self.w,self.h = self:minSize()
end

function Window:layoutExpand(bb)
  assertf(self.w and self.h, "window %s has no dimensions at start of expansion phase!", self)
  self.w,self.h = self:maxSize(bb)
  assertf(self.w and self.h, "window %s has no dimensions after maxSize()!", self)
  self.x,self.y = self:autoPosition(bb)
  bb = self:getChildBB()
  for child in self:children() do
    child:layoutExpand(bb)
  end
  self:postLayout()
end

function Window:getChildBB()
  local bb = {
    name = "childBB[%s]" % {self};
    x = self.margins.lf;
    y = self.margins.up;
    w = self.w - self.margins.lf - self.margins.rt;
    h = self.h - self.margins.up - self.margins.dn;
  }
  return bb
end

--
-- Support functions for layout()
--

-- Minimum size of a window. For fixed size windows, this is the fixed size. For
-- all other window configurations, this is the minimum size such that all of the
-- window's children fit within theg window's CBB.
function Window:minSize()
  local function axis(want, min)
    if 0 < want and want < inf then
      return want
    else
      return min
    end
  end
  local w,h = self:getChildSize()
  return axis(self.size[1], w + self.margins.lf + self.margins.rt),
         axis(self.size[2], h + self.margins.up + self.margins.dn)
end

-- Maximum size of a window. For fixed size windows, this is the fixed size. For
-- windows with the 'min' sizing rule, this is the same as minSize(). For windows
-- with the 'max' sizing rule or relative sizing, this is calculated based on the
-- bounding box passed in.
function Window:maxSize(bb)
  assertf(bb.w and bb.h, '%s: maxSize: bb missing dimensions: %s %s', self, type(bb), repr(bb))
  local function axis(want, max)
    if want == inf then
      return max
    elseif want > 0 then
      assertf(want <= max, "window %s with fixed axis %d exceeds size of bounding box %d (%dx%d)", self, want, max, bb.w, bb.h)
      return want
    elseif want < 0 then
      assert(max + want > 0, "relative-size window has size ≤ 0")
      return max + want
    end
  end
  return axis(self.size[1], bb.w) or self.w,
         axis(self.size[2], bb.h) or self.h
end

function Window:postLayout() end

-- Size of the smallest bounding box that can contain all of the window's children.
function Window:getChildSize()
  w,h = 0,0
  for child in self:children() do
    w = w:max(child.w)
    h = h:max(child.h)
  end
  return w,h
end

-- Set the final position of a window, based on its positioning rules. This is
-- called only after the sizes of both this window and its parent are finalized.
function Window:autoPosition(bb)
  assertf(self.w and self.h, "window %s has no dimensions", self)
  assertf(bb.w and bb.h, "parent of windows %s has no dimensions", self)
  return ((bb.w - self.w) * self.position[1]):floor():max(0),
         ((bb.h - self.h) * self.position[2]):floor():max(0)
end


--
-- Event handling
--

-- Called to handle a keystroke from the user. Key is the name of the keystroke;
-- cmd, if set, is the name of the corresponding command based on the current
-- bindings.
-- First it passes the event to all of its children, in descending order; if
-- any of them handle it, it immediately returns.
-- Then it checks to see if it knows how to handle it, and if so, calls the
-- handler. The handler can explicitly return false for "I did not handle this
-- event, propagate it normally"; any other return, including nil, counts as
-- handling it.
-- It checks the children in descending order so that the topmost (i.e. most
-- recently attached) window gets to see it first.
-- FIXME: this is an awful name since this is the only way to handle *all* events,
-- not just key events (and not all events are key events anymore).
function Window:keyEvent(key, cmd)
  if not self.visible then return false end
  if self.can_focus and not self.focused then return false end
  for i=#self._children,1,-1 do
    if self._children[i]:keyEvent(key, cmd) == true then return true end
  end
  return self:handleEvent(key, cmd)
end

function Window:handleEvent(key, cmd)
  assert(key or cmd, 'at least one of key or cmd must be set when calling handleEvent')
  local handlers
  if cmd and key then
    handlers = { 'cmd_'..cmd, 'cmd_any', 'key_'..key, 'key_any' }
  elseif cmd then
    handlers = { 'cmd_'..cmd, 'cmd_any' }
  elseif key then
    handlers = { 'key_'..key, 'key_any' }
  end
  for _,name in ipairs(handlers) do
    if self[name] then
      local r = self[name](self, key, cmd)
      if r == true then return true end
      assertf(r == false, 'event handler %s:%s must return either true or false', self, name)
    end
  end
  return false
end

function Window:render() end

function Window:renderChildren()
  tty.push(self:getChildBB())
  for child in self:children() do
    tty.push(child)
    child:renderAll()
    tty.pop()
  end
  tty.pop()
end

function Window:renderAll()
  local t
  if flags.parsed.ui_perf then
    t = os.clock()
    log.debug('  begin: %s', self)
  end
  self:render()
  self:renderChildren()
  if flags.parsed.ui_perf then
    t = os.clock() - t
    log.debug('ui-perf: %s: %3f', self, t)
  end
end

-- WARNING WARNING WARNING
-- does not call :layout() on the attached window!
-- caller must layout at some point by hand!
-- TODO: fix this!
-- WARNING WARNING WARNING
function Window:attach(subwin)
  assert(not subwin.parent, 'attempt to attach non-orphan window')
  table.insert(self._children, subwin)
  subwin.parent = self
end

function Window:detach(subwin)
  if not subwin then
    return self.parent:detach(self)
  end

  for i,v in ipairs(self._children) do
    if v == subwin then
      table.remove(self._children, i)
      v.parent = nil
      return
    end
  end
  error('Attempt to remove subwindow %s from %s', subwin.name, self.name)
end

function Window:destroy()
  self:detach()
  self.renderAll = function() error 'renderAll called on destroyed window' end
end

return Window
