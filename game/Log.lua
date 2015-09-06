local Log = Object:subclass {}

function Log:__init()
  self:clear()
end

function Log:__call(fmt, ...)
  table.insert(self._head, fmt:format(...))
end

function Log:clear()
  self._turns = {}
  self._head = {}
  self._next_turn = 1
end

function Log:turns()
  return coroutine.wrap(function()
    for i=(self._next_turn - 20):max(1),self._next_turn-1 do
      coroutine.yield(self._turns[i])
    end
  end)
end

function Log:currentTurn()
  return self._head
end

function Log:nextTurn()
  if #self._head > 0 then
    self._turns[self._next_turn] = self._head
    self._turns[self._next_turn-20] = nil  -- FIXME: replace 20 with setting
    self._head = {}
    self._next_turn = self._next_turn + 1
  end
end

return Log
