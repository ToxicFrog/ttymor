--
-- A one-line widget that can be expanded to show its contents.
-- Used to implement trees.
--
-- .text is the contents of the expander header (and thus what will be shown when
-- it is fully collapsed).
-- .content is the content displayed when the expander is expanded.
-- If .content is not set, the array part of the constructor must be set instead;
-- .content will be set to a VList containing that data.
-- It is an error for neither or both to be set.
--
local TextLine = require 'ui.TextLine'
local VList = require 'ui.VList'

local Expander = VList:subclass {
  expanded = false;
  size = { inf, 0 };
}

function Expander:__init(data)
  if #data > 0 then
    assert(not data.content, "An Expander can't have both .content and array parts")
    data.content = ui.VList {}
    for i,v in ipairs(data) do
      data.content:attach(v)
      data[i] = nil
    end
  end
  VList.__init(self, data)
  if not self.content then
    assert(#self > 0, "Expander created without content")
  end
  self._header = TextLine { text = self.text; can_focus = true; }
  function self._header.cmd_activate()
    self:expand(not self.expanded)
    ui.layout()
    return true
  end
  self.content.margins = { up = 0; dn = 0; lf = 1; rt = 0 };
  self:attach(self._header)
  self:attach(self.content)
  self:expand(self.expanded)
end

-- To update all our bits to take the current expansion state into account.
function Expander:expand(expanded)
  self.expanded = expanded
  self._header.text = (expanded and "[-] " or "[+] ")..self.text
  self.content.visible = expanded
end

return Expander
