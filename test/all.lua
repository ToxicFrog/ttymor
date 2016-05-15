lu = require('test.luaunit')
require 'test.util'

require 'test.ui.EntityLine'

log.setlevel 'fatal'

runner = lu.LuaUnit.new()
os.exit( runner:runSuite() )
