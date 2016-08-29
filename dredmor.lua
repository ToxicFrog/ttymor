require 'util'
require 'xml'
require 'settings'

flags.register "dredmor-dirs" {
  default = { "./dredxml/game" };
  type = flags.list;
  help = "Paths to Dredmor XML directories, e.g. --dredmor-dirs=~/Games/Dredmor/game,~/Games/Dredmor/expansion/game";
}

dredmor = {}

require 'dredmor.itemDB'
require 'dredmor.monDB'
require 'dredmor.rooms'
require 'dredmor.tweakDB'
require 'dredmor.text'

function dredmor.loadAll()
  dredmor.loadItems()
  dredmor.loadMonsters()
  dredmor.loadRooms()
  dredmor.loadTweaks()
  dredmor.loadText()
end

function dredmor.loadFiles(fn, suffix)
  for _,path in ipairs(flags 'dredmor-dirs') do
    path = path..suffix
    if io.exists(path) then
      log.info('Loading: %s', path)
      fn(path)
    else
      log.warning('Missing: %s', path)
    end
  end
end
