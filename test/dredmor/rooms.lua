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
  lu.assertNotNil(dredmor.room 'Test Room')
  lu.assertNotNil(dredmor.room 'Large Test Room')
  lu.assertNotNil(dredmor.room 'Angled Test Room')
end

function TestDredmorRoomsXML:testRoomProperties()
  dredmor.loadRooms()
  lu.assertHasFields(dredmor.room 'Test Room', {
    name = 'Test Room';
    w = 5; h = 5; footprint = 25;
    special = true;
    minlevel = 2; maxlevel = 3;
  })
  lu.assertHasFields(dredmor.room 'Large Test Room', {
    name = 'Large Test Room';
    w = 7; h = 5; footprint = 35;
  })
  lu.assertHasFields(dredmor.room 'Angled Test Room', {
    name = 'Angled Test Room';
    w = 7; h = 5; footprint = 29;
  })
end

function TestDredmorRoomsXML:testRoomEntities()
  dredmor.loadRooms()
  local room = dredmor.room('Test Room')
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
