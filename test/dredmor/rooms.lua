-- Tests for the Dredmor rooms.xml loader -- dredmor.rooms and dredmor.Room

require 'dredmor'
flags.parse { '--dredmor-dirs=test/dredmor' }
dredmor.loadRooms()

TestDredmorRoomsXML = {}

function TestDredmorRoomsXML:testLoadRooms()
  lu.assertNotNil(dredmor.room 'Test Room')
  lu.assertNotNil(dredmor.room 'Large Test Room')
  lu.assertNotNil(dredmor.room 'Angled Test Room')
end

function TestDredmorRoomsXML:testRoomProperties()
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
  local room = dredmor.room('Test Room')
  lu.assertEquals(room._entities[1], {
    type = "Wall"; name = "Test Object XY"; x = 3; y = 3;
    desc = "using coordinates";
    Render = { face = '♦' };
  })
  lu.assertEquals(room._entities[2], {
    type = "Floor"; name = "Test Object At"; x = 1; y = 1;
    desc = "using waypoint";
    Render = { face = '◊' };
  })
end

local function alldoors(room)
  local doors = {}
  for x,y,dir in room:doors() do
    table.insert(doors, {x,y,dir})
  end
  return doors
end

function TestDredmorRoomsXML:testDoors()
  lu.assertEquals(
    alldoors(dredmor.room 'Test Room'),
    { {2,0,'n'}, {0,2,'w'}, {4,2,'e'}, {2,4,'s'} })
  lu.assertEquals(
    alldoors(dredmor.room 'Large Test Room'),
    { {0,2,'w'}, {6,2,'e'} })
  lu.assertEquals(
    alldoors(dredmor.room 'Angled Test Room'),
    { {0,2,'w'}, {2,4,'s'} })
  lu.assertEquals(
    alldoors(dredmor.room 'Deceptive Dimensions'),
    {})
  lu.assertEquals(
    alldoors(dredmor.room 'Weird Doors'),
    { {3,1,'n'}, {1,3,'w'}, {5,3,'e'}, {3,5,'s'} })
end
