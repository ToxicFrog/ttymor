require 'dredmor'
flags.parse { '--dredmor-dirs=test/dredmor' }

-- Tests for the Dredmor rooms.xml loader
TestDredmorRoomsXML = {}
-- dredmor = {}

-- flags.register "dredmor-dirs" {
--   default = "./dredmor";
--   type = flags.list;
--   help = "Paths to Dredmor XML directories, e.g. --dredmor-dirs=~/Games/Dredmor/game,~/Games/Dredmor/expansion/game";
-- }

--require 'dredmor.rooms'

function TestDredmorRoomsXML:testLoadRooms()
  dredmor.loadRooms()
  local room = dredmor.room('Test Room')
  lu.assertNotNil(room)
  lu.assertEquals(room.name, 'Test Room')
  lu.assertEquals(room.w, 5)
  lu.assertEquals(room.h, 5)
  lu.assertEquals(room.footprint, 20)
  lu.assertTrue(room.special)
  lu.assertEquals(room.minlevel, 2)
  lu.assertEquals(room.maxlevel, 3)
  lu.assertEquals(room.entities[1], {
    type = "Wall"; name = "Test Object XY"; x = 3; y = 3;
    desc = "using coordinates";
    Render = { face = '♦' };
  })
  lu.assertEquals(room.entities[2], {
    type = "Floor"; name = "Test Object At"; x = 1; y = 1;
    desc = "using waypoint";
    Render = { face = '◊' };
  })
end
