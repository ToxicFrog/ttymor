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
  lu.assertHasFields(dredmor.room 'Deceptive Dimensions', {
    w = 7; h = 6; footprint = 20;
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

function TestDredmorRoomsXML:testRoomCollision()
  local test,large,angled =
    dredmor.room('Test Room'), dredmor.room('Large Test Room'), dredmor.room('Angled Test Room')

  -- test room does not overlap with itself
  lu.assertFalse(test:collidesWith(test, 5, 0))
  lu.assertFalse(test:collidesWith(test, 0, 5))

  -- test room overlaps with itself, but in a compatible manner
  lu.assertFalse(test:collidesWith(test, 4, 0))
  lu.assertFalse(test:collidesWith(test, 0, 4))

  -- ...and in an incompatible manner
  lu.assertTrue(test:collidesWith(test, 4, 1))
  lu.assertTrue(test:collidesWith(test, 1, 4))

  -- angled room shares a wall with test room's south door
  lu.assertTrue(test:collidesWith(angled, 0, 4))
  lu.assertTrue(angled:collidesWith(test, 0, -4))

  -- angled room's BB collides with test, but the actual geometry doesn't
  lu.assertFalse(test:collidesWith(angled, -4, 3))
  lu.assertFalse(angled:collidesWith(test, 4, -3))

  -- Large room's corner overlaps the edge of test room's south door. This edge
  -- shows up as # in the grid, but should be treated as D for the purposes of
  -- collision detection.
  lu.assertTrue(test:collidesWith(large, 3, 4))
  lu.assertTrue(large:collidesWith(test, -3, -4))
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
