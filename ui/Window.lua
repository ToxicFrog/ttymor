local Window = Object:subclass {
  visible = false;
  position = 'center';
}

flags.register 'ui-perf' {
  default = false;
  help = 'Log detailed rendering performance info.';
}

function Window:__init(...)
  Object.__init(self, ...)
  self.children = {}
end

-- Calculate the window's preferred size. By default this just asserts that
-- width and height are set, but subclasses may do more.
function Window:resize()
  assert(self.w and self.h, 'window created without width or height')
end

-- Calculate the window's (x,y) position and bounds based on the 'position'
-- property and the size of the parent.
function Window:reposition()
  self:resize()
  if self.position == 'fixed' then
    assert(self.x and self.y, 'position == fixed requires x and y to be specified')
  elseif self.position == 'center' then
    self.w = self.w:min(self.parent.w)
    self.h = self.h:min(self.parent.h)
    self.x = ((self.parent.w - self.w)/2):floor():max(0)
    self.y = ((self.parent.h - self.h)/2):floor():max(0)
  else
    errorf('unsupported value "%s" for position', self.position)
  end
end

function Window:show()
  self.visible = true
end

function Window:hide()
  self.visible = false
end

function Window:renderAll()
  if not self.visible then return end
  local t = os.clock()
  tty.pushwin(self)
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
  subwin:reposition()
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
      return
    end
  end
  errorf('Attempt to remove subwindow %s from %s', subwin.name, self.name)
end

function Window:destroy()
  log.debug('destroy window', self.name)
  self:detach()
  self.renderAll = function() error 'renderAll called on destroyed window' end
end

return Window
