local EntityLine = require 'ui.EntityLine'

TestEntityLine = {}

function TestEntityLine:setup()
  self.obj = entity.create {
    type = 'TestEntity';
    id = 1;
  }
  self.subj = entity.create {
    type = 'TestEntity';
    id = 2;
  }
  game = {}
  function game.get() return self.subj end
end

function TestEntityLine:test__tostring()
  local el = ui.EntityLine { focused = true; entity = self.obj }
  lu.assertEquals(tostring(el), 'EntityLine[<TestEntity$1:Test>]')
end

function TestEntityLine:testVerbPassthrough()
  local el = ui.EntityLine { focused = true; entity = self.obj }
  el:keyEvent('x', 'verb_examine')
  el:keyEvent(',', 'verb_pickup')
  el:keyEvent('.', 'verb_drop')
  el:keyEvent('enter', 'activate')
  lu.assertEquals(self.subj.messages,
    { verb_examine = 1, verb_pickup = 1, verb_drop = 1 })
  lu.assertEquals(self.obj.messages,
    { verb_examine_by = 1, verb_pickup_by = 1, verb_drop_by = 1 })
  lu.assertEquals(self.subj.commands, {})
  lu.assertEquals(self.obj.commands, { activate = 1 })
end

function TestEntityLine:testDefaultVerb()
  local el = ui.EntityLine {
    focused = true;
    entity = self.obj;
    default_verb = 'examine';
  }

  el:keyEvent('enter', 'activate')
  lu.assertEquals(self.subj.messages,
    { verb_examine = 1 })
  lu.assertEquals(self.obj.messages,
    { verb_examine_by = 1 })
  lu.assertEquals(self.subj.commands, {})
  lu.assertEquals(self.obj.commands, {})
end
