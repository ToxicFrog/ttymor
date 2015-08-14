local Blocker = {}

function Blocker:blocks(type)
  for _,blocked in ipairs(self.Blocker) do
    if blocked == type then
      return true
    end
  end
end

return Blocker
