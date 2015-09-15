love = {
  event = {};
  timer = {};
}

local function main(...)
  love.load {...}
  while true do
    love.draw()
    local key = tty.readkey()
    love.keypressed(key)
    love.update(0.033)
  end
end

function love.main(...)
  return xpcall(main, love.errhand, ...)
end

function love.event.quit()
  if love.quit() then return end
  os.exit(0)
end

function love.timer.sleep(t)
end
