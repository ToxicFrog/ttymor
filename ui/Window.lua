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

function Window:children()
  return coroutine.wrap(function()
    for _,child in ipairs(self._children) do
      coroutine.yield(child)
    end
  end)
end

-- Perform window layout/sizing.
-- This is kind of nasty.
-- We need to know the size of our children to determine our own size, since
-- our size may be <the minimum needed to enclose our children>. But we need
-- to be able to pass our bounding box on to our children, which may not be the
-- same as the BB our parent passed us, if we have fixed/relative size axes
-- rather than min/max ones.
-- So we figure out the child bounding box first, pass that to all our children
-- and tell them to :layout(). Having done that, we can figure out own own size,
-- and once we know *that* we also know where our children need to go based on
-- their size and positioning rules.
function Window:layout(bb)
  if not self.visible then
    -- Invisible windows take up no space and don't participate in layout.
    self.w,self.h = 0,0
    return
  end

  bb = bb or { x=0; y=0; w=self.parent.w; h=self.parent.h; }

  -- Get our provisional size.
  self:requestSize(bb)
  -- Get the bounding box for our children.
  local ch_bb = self:getChildBB()

  for child in self:children() do
    local _ = self:getChildBB()
    child:layout(ch_bb)
  end

  self:finalizeSize(bb)

  for child in self:children() do
    child:finalizePosition(ch_bb)
  end
end

function Window:getChildBB()
  local bb ={
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

-- Calculate the window's maximum request size. This is the most size the window
-- could possibly request of its parent; for this reason, 0-size windows will
-- request max, since they don't yet know how big their children are.
function Window:requestSize(bb)
  local function axis(want, max)
    if want == inf or want == 0 then
      return max
    elseif want > 0 then
      assertf(want <= max, "window %s with fixed axis %d exceeds size of bounding box %d (%dx%d)", self, want, max, bb.w, bb.h)
      return want
    elseif want < 0 then
      assert(max + want > 0, "relative-size window has size ≤ 0")
      return max + want
    end
  end
  self.w = axis(self.size[1], bb.w)
  self.h = axis(self.size[2], bb.h)
end

function Window:getChildSize()
  w,h = 0,0
  for child in self:children() do
    w = w:max(child.w)
    h = h:max(child.h)
  end
  return w,h
end

-- Set the final size of a window, based on its sizing rules. This is called
-- only after the size of all the children is known.
function Window:finalizeSize(bb)
  local function axis(want, min, max)
    -- Only elements with a size of 0 need to be resized here; everything else
    -- retains the size it originally requested.
    if want == 0 then
      return min
    else
      return max
    end
  end
  local ch_w,ch_h = self:getChildSize()
  self.w = axis(self.size[1], ch_w + self.margins.lf + self.margins.rt, self.w)
  self.h = axis(self.size[2], ch_h + self.margins.up + self.margins.up, self.h)
end

-- Set the final position of a window, based on its positioning rules. This is
-- called only after the sizes of both this window and its parent are finalized.
function Window:finalizePosition(bb)
  self.x = ((bb.w - self.w) * self.position[1]):floor():max(0)
  self.y = ((bb.h - self.h) * self.position[2]):floor():max(0)
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

function Window:show()
  self.visible = true
end

function Window:hide()
  self.visible = false
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
  if not self.visible then return end
  local t
  if flags.parsed.ui_perf and self.name then
    t = os.clock()
    log.debug('  begin: %s', self.name)
  end
  self:render()
  self:renderChildren()
  if flags.parsed.ui_perf and self.name then
    t = os.clock() - t
    log.debug('ui-perf: %s: %3f', self.name, t)
  end
end

-- WARNING WARNING WARNING
-- does not call :layout() on the attached window!
-- caller must layout at some point by hand!
-- TODO: fix this!
-- WARNING WARNING WARNING
function Window:attach(subwin)
  log.debug('%s: attaching child %s', self, subwin)
  assert(not subwin.parent, 'attempt to attach non-orphan window')
  table.insert(self._children, subwin)
  subwin.parent = self
end

function Window:detach(subwin)
  if not subwin then
    return self.parent:detach(self)
  end
  log.debug('%s: detach child %s', self, subwin)

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
  log.debug('destroy window: %s', self)
  self:detach()
  self.renderAll = function() error 'renderAll called on destroyed window' end
end

return Window
