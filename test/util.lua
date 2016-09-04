require 'Object'
require 'util'
require 'ui'
require 'game.entity'
require 'builtins'

function lu.assertHasFields(actual, expected)
  for k,v in pairs(expected) do
    lu.assertEquals(actual[k], v)
  end
end

local TestComponent = {}
package.loaded['components.TestComponent'] = TestComponent

function TestComponent:msg_init()
  local mt = { __index = function() return 0 end }
  self.messages = setmetatable({}, mt)
  self.commands = setmetatable({}, mt)
  self.keys = setmetatable({}, mt)
  function self:message(type)
    self.messages[type] = self.messages[type] + 1
  end
end

function TestComponent:cmd_any(key, cmd)
  self.commands[cmd] = self.commands[cmd] + 1
  return false
end

function TestComponent:key_any(key, cmd)
  self.keys[key] = self.keys[key] + 1
  return false
end

function TestComponent:verb(verb, object)
  self:message('verb_'..verb, object)
  object:message('verb_'..verb..'_by', self)
end

entity.register 'TestEntity' {
  name = 'Test';
  TestComponent = {};
}
