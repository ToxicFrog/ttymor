local Window = Object:subclass {
  visible = true;
  position = { 0, 0 };
  size = { 0, 0 };
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
function Window:layout(max_w, max_h)
  if not self.visible then
    -- Invisible windows take up no space and don't participate in layout.
    self.w,self.h = 0,0
    return
  end

  max_w = max_w or self.parent.w
  max_h = max_h or self.parent.h
  log.debug('Layout begin: %s, BB: %dx%d', self, max_w, max_h)
  -- sizing of BB available to children, taking into account our sizing rules
  local ch_w,ch_h = self:getBounds(max_w, max_h)
  -- margins, which affect BB usable for children
  local up,dn,lf,rt = self:getMargins()
  ch_w = ch_w - lf - rt
  ch_h = ch_h - up - dn

  for child in self:children() do
    child:layout(ch_w, ch_h)
  end

  self.w,self.h = self:getSize(max_w, max_h)
  log.debug("Size: %s: %dx%d", self, self.w, self.h)

  for child in self:children() do
    child.x,child.y = child:getPosition(ch_w, ch_h)
    child.x,child.y = child.x + lf,child.y + up
    log.debug("Position: %s: %d,%d", child.name, child.x, child.y)
  end
  log.debug("Layout end: %s", self)
end

--
-- Support functions for layout()
--

local function bound_axis(max, want)
  if want == inf or want == 0 then
    return max
  elseif want > 0 then
    assert(want <= max, "fixed-size window exceeds size of bounding box")
    return want
  elseif want < 0 then
    assert(max + want > 0, "relative-size window has size ≤ 0")
    return max + want
  end
end

-- Return the *actual* maximum bounding box of this window, given the BB passed
-- down by our parents.
function Window:getBounds(max_w, max_h)
  return bound_axis(max_w, self.size[1]), bound_axis(max_h, self.size[2])
end

-- Return the (top,bottom,left,right) margins of the window. This is the
-- difference between the true maximum bounding box, and the space available
-- for children to use.
function Window:getMargins()
  return 0,0,0,0
end

local function size_axis(self, max, want, min)
  log.debug("size_axis: max=%d want=%f min=%d",
    max, want, min)
  if want == inf then
    return max
  elseif want > 0 then
    return want
  elseif want == 0 then
    return min
  elseif want < 0 then
    return max + want
  else
    error()
  end
end

-- getChildSize doesn't do anything with the passed width and height, but they
-- are provided for the use of subclasses, like Box, which are capable of
-- shrinking their children to fit into smaller bounding boxes.
function Window:getChildSize(w, h)
  w,h = 0,0
  for child in self:children() do
    w = w:max(child.w)
    h = h:max(child.h)
  end
  return w,h
end

function Window:getSize(max_w, max_h)
  local up,dn,lf,rt = self:getMargins()
  local ch_w,ch_h = self:getChildSize(max_w-lf-rt, max_h-up-dn)
  return size_axis(self, max_w, self.size[1], ch_w+lf+rt),
         size_axis(self, max_h, self.size[2], ch_h+up+dn)
end

local function position_axis(bb, grav, size)
  return ((bb - size) * grav):floor()
end

function Window:getPosition(max_w, max_h)
  return position_axis(max_w, self.position[1], self.w),
         position_axis(max_h, self.position[2], self.h)
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
function Window:keyEvent(key, cmd)
  if not self.visible then return false end
  for i=#self._children,1,-1 do
    if self._children[i]:keyEvent(key, cmd) == true then return true end
  end
  return self:handleEvent(key, cmd)
end

function Window:handleEvent(key, cmd)
  local handlers
  if cmd then
    handlers = { 'cmd_'..cmd, 'cmd_any', 'key_'..key, 'key_any' }
  else
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
  for child in self:children() do
    tty.push(child)
    child:renderAll()
    tty.pop()
  end
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
  log.debug('destroy window: %s', self.name)
  self:detach()
  self.renderAll = function() error 'renderAll called on destroyed window' end
end

return Window
