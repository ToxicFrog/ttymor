require 'util'
require 'xml'

flags.register "dredmor-dir" {
  default = "./dredmor";
  type = flags.string;
  help = "path to Dungeons of Dredmor installation";
}

dredmor = {}

require 'dredmor.rooms'
