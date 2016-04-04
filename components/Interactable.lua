local verb_info = require 'ui.verbs'

local Interactable = {}

function Interactable:interactedWith()
  local tree = { name = self.name }
  local verbs = {}; self:message('verbs', verbs)
  for verb in pairs(verbs) do
    assert(verb_info[verb], verb)
    table.insert(tree, {
      name = verb_info[verb].name;
      help = verb_info[verb].help;
      activate = function(node)
        node.tree:cancel()
        game.get('player'):verb(verb, self)
      end;
    })
  end
  ui.tree(tree)
end

return Interactable
