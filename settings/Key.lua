local Key = require 'settings.Raw' :subclass {}

function Key:display()
  return '[%6s][%6s]' % {
    self.value[1] or '------', self.value[2] or '------'
  }
end

function Key:activate()
  local msg = ui.message(self.name, "Press any key...")
  msg.cmd_any = nil
  function msg.key_any(msg, key)
    if key ~= self.value[1] then
      self:set { key, self.value[1] }
    end
    msg:destroy()
    return true
  end
end

function Key:reset()
  self:set {}
end

return Key
