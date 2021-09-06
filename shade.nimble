# Package

version       = "0.1.0"
author        = "Einheit Technologies"
description   = "Game Engine"
license       = "GPLv2.0"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["shade"]


# Dependencies

requires "nim >= 1.4.6"
requires "opengl >= 1.1.0"
requires "staticglfw >= 4.1.2"
requires "pixie >= 2.1.1"

# Tasks
task example, "Runs the basic example":
  exec "nim r examples/basic/basic_game.nim"

task debug, "Runs the basic example":
  exec "nim -d:collisionoutlines -d:inputdebug r examples/basic/basic_game.nim"
