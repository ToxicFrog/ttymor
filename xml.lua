-- Helper functions for the SLAXML/SLAXDOM library.
local slaxdom = require 'slaxdom'

xml = {}

function xml.parse(str)
  return slaxdom:dom(str)
end

function xml.load(file)
  return xml.parse(io.readfile(file))
end

function xml.walk(root, filter)
  local fn
  if type(filter) == 'string' then
    function fn(elem) return elem.name == filter end
  elseif type(filter) == 'table' then
    function fn(elem) return filter[elem.name] end
  elseif type(filter) == 'function' then
    fn = filter
  else
    fn = function() return true end
  end

  local function xml_walk(self)
    if fn(self) then
      coroutine.yield(self)
    end
    for i,child in ipairs(self.el) do
      xml_walk(child)
    end
  end
  return coroutine.wrap(xml_walk),root
end
