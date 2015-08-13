require 'util'
require 'xml'
require 'settings'

flags.register "dredmor-dir" {
  default = "./dredmor";
  type = flags.string;
  help = "path to Dungeons of Dredmor installation";
}

dredmor = {}

require 'dredmor.monDB'
require 'dredmor.rooms'
require 'dredmor.tweaks'

function dredmor.loadAll()
  dredmor.loadMonsters()
  dredmor.loadRooms()
  dredmor.loadTweaks()
end
