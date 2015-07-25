require 'util'
require 'xml'

flags.register "dredmor-path" {
  default = "./dredmor";
  type = flags.string;
  help = "path to Dungeons of Dredmor installation";
}

dredmor = {}

require 'dredmor.rooms'
