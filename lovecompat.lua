love = {}

love.event = {}

function love.event.quit()
  if love.quit() then return end
  os.exit(0)
end

local function main(...)
  love.load {...}
  while true do
    love.draw()
    love.update(0)
  end
end

function love.main(...)
  return xpcall(main, love.errhand, ...)
end
