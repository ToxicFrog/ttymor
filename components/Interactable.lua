local verb_info = require 'ui.verbs'

local Interactable = {}

function Interactable:interactedWith()
  local tree = { title = self.name }
  local verbs = {}; self:message('verbs', verbs)
  for verb in pairs(verbs) do
    assert(verb_info[verb], verb)
    table.insert(tree, {
      text = verb_info[verb].name;
      help = verb_info[verb].help;
      cmd_activate = function()
        ui.sendEvent(nil, 'cancel')
        game.get('player'):verb(verb, self)
        return true
      end;
    })
  end
  ui.tree(tree)
end

return Interactable
