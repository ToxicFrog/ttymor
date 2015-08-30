local Blocker = {}

function Blocker:blocks(type)
  return self.Blocker[type]
end

return Blocker
