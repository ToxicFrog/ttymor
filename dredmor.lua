require 'util'
require 'xml'
require 'settings'

flags.register "dredmor-dir" {
  default = "./dredmor";
  type = flags.string;
  help = "path to Dungeons of Dredmor installation";
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
