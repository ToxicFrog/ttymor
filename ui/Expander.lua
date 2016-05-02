--
-- A one-line widget that can be expanded to show its contents.
-- Used to implement trees.
--
local TextLine = require 'ui.TextLine'
local VList = require 'ui.VList'

local Expander = VList:subclass {
  expanded = false;
}

function Expander:__init(...)
  VList.__init(self, ...)
  assert(self.content, "an Expander requires both .text and .content")
  self._header = TextLine { text = self.text; can_focus = true; }
  function self._header.activate(header, tree)
    self:expand(not self.expanded)
    ui.layout()
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
