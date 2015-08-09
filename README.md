# Dungeons of Demake/TTYmor (working title)

This will one day (hopefully) be a tty-based "demake" of Dungeons of Dredmor, but at the moment it's just some prototype code.

At the moment it's not very portable. It *requires*:

  * LuaJIT
  * A vt220-compatible, UTF-8 capable terminal emulator such as Konsole
  * The 'mkdir' command

which as a practical matter means it only works on linux (and probably OSX, but I haven't tested it there). It would likely work on windows under Cygwin, if you ran it under urxvt or something similar.

There are plans for a native graphical version, probably love2d-based, and the ttylib is designed to make it easy to implement, but that's a long way off.

To run it:

  * `git clone --recursive` to get the repo and all submodules
  * `./ttymor --dredmor-dir=path/to/dredmor`

Alternately, you can copy all the Dredmor XML files (preserving directory structure!) into a `dredxml` directory alongside the ttymor script and it'll find it automatically.
