require 'repr'

local function monsterFromXML(node)
  return xml.attrs(node)
end

-- Master table of all monsters, indexed by monster name.
local monsters = {}

local function loadMonsters(path)
  local dom = xml.load(path)
  local count = 0
  for mondef in xml.walk(dom.root, 'monster') do
    if monsters[mondef.attr.name] then
      log.debug("skipping duplicate monster definition %s", mondef.attr.name)
    else
      count = count+1
      local monster = monsterFromXML(mondef)
      monsters[monster.name] = monster
    end
  end
  log.debug("Loaded %d monsters from %s", count, path)
end

function dredmor.loadMonsters()
  monsters = {}
  return dredmor.loadFiles(loadMonsters, '/monDB.xml')
end

function dredmor.monsters(filter)
  local R = {}
  filter = filter or f' => true'
  for _,monster in pairs(monsters) do
    if filter(monster) then
      R[monster.name] = monster
      table.insert(R, monster)
    end
  end
  log.debug("Returning filtered list of %d monsters", #R)
  return R
end

function dredmor.monster(name)
  return monsters[name]
end
