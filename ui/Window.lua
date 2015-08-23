local Window = Object:subclass {
  visible = false;
}

flags.register 'ui-perf' {
  default = false;
  help = 'Log detailed rendering performance info.';
}

function Window:__init(...)
  Object.__init(self, ...)
  self.children = {}
  assertf(self.parent, "attempt to create orphan window %s", self.name)
  self.parent:attach(self)

  if not self.x then
    self:center()
  end
end

function Window:center()
  self.w = self.w:min(self.parent.w)
  self.h = self.h:min(self.parent.h)
  self.x = ((self.parent.w - self.w)/2):floor():max(0)
  self.y = ((self.parent.h - self.h)/2):floor():max(0)
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
  assertf(subwin.parent == self, 'Window %s tried to attach to %s, but is already owned by %s',
      subwin.name, self.name, (subwin.parent or {}).name)
  table.insert(self.children, subwin)
  subwin.parent = self
end

function Window:remove(subwin)
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
  self.parent:remove(self)
  self.renderAll = function() error 'renderAll called on destroyed window' end
end

ui.Window = Window
return Window
