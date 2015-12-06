local Window = Object:subclass {
  visible = false;
  position = 'center';
  colour = { 255, 255, 255, 0, 0, 0 };
}

flags.register 'ui-perf' {
  default = false;
  help = 'Log detailed rendering performance info.';
}

function Window:__init(...)
  Object.__init(self, ...)
  self.children = {}
end

-- Given the width and height available for the window to use, set its preferred
-- width and height, and then resize its children.
-- Contract: the w and h of this window may not exceed the values passed in.
-- If this cannot be satisfied, it must assert.
-- Subclasses should override this to implement e.g. margins.
function Window:resize(w, h)
  return self.w,self.h
end

function Window:resizeChildren(w, h)
  for _,child in ipairs(self.children) do
    child:resize(w, h)
  end
end

-- Calculate the window's (x,y) position and bounds based on the 'position'
-- property and the size of the parent.
function Window:reposition(w, h)
  self:resizeChildren(self:resize(w, h))
  assertf(self.w and self.h, 'window %s has no width or height', self.name)
  assert(self.w <= w and self.h <= h, 'window size exceeds container size')
  if self.position == 'fixed' then
    -- pass
  elseif self.position == 'center' then
    self.x = ((w - self.w)/2):floor():max(0)
    self.y = ((h - self.h)/2):floor():max(0)
  else
    error('unsupported value "%s" for position', self.position)
  end
end

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
  for i=#self.children,1,-1 do
    if self.children[i]:keyEvent(key, cmd) == true then return true end
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

function Window:renderAll()
  if not self.visible then return end
  local t
  if flags.parsed.ui_perf and self.name then
    t = os.clock()
    log.debug('  begin: %s', self.name)
  end
  tty.pushwin(self)
  if self.colour then
    tty.colour(unpack(self.colour))
  end
  self:render()
  for _,win in ipairs(self.children) do
    win:renderAll()
  end
  tty.popwin()
  if flags.parsed.ui_perf and self.name then
    t = os.clock() - t
    log.debug('ui-perf: %s: %3f', self.name, t)
  end
end

function Window:attach(subwin)
  log.debug('%s: attaching child %s', self.name, subwin.name)
  assert(not subwin.parent, 'attempt to attach non-orphan window')
  table.insert(self.children, subwin)
  subwin.parent = self
  subwin:reposition(self:resize(self.w, self.h))
  log.debug('  child %dx%d @ (%d,%d)', subwin.w, subwin.h, subwin.x, subwin.y)
end

function Window:detach(subwin)
  if not subwin then
    return self.parent:detach(self)
  end
  log.debug('detach %s from %s', subwin.name, self.name)

  for i,v in ipairs(self.children) do
    if v == subwin then
      table.remove(self.children, i)
      v.parent = nil
      return
    end
  end
  error('Attempt to remove subwindow %s from %s', subwin.name, self.name)
end

function Window:destroy()
  log.debug('destroy window', self.name)
  self:detach()
  self.renderAll = function() error 'renderAll called on destroyed window' end
end

return Window
