lu = require('test.luaunit')
require 'test.util'

require 'test.ui.EntityLine'
require 'test.dredmor.rooms'

log.setlevel 'error'
log.setfile(io.stderr)

runner = lu.LuaUnit.new()
os.exit( runner:runSuite() )
