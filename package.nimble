# Package

version       = "0.1.0"
author        = "Akito <the@akito.ooo"
description   = "A new awesome nimble sue"
license       = "GPL-3.0-or-later"
srcDir        = "src"
bin           = @["sue"]
skipDirs      = @["tasks"]
skipFiles     = @["README.md"]
skipExt       = @["nim"]


# Dependencies

requires "nim >= 1.0.6"


# Tasks

task test, "Run test.":
  exec "nim cc -r tests/test.nim"
task configure, "Configure project.":
  exec "git fetch"
  exec "git pull"
  exec "git checkout master"
  exec "git submodule update --init --recursive"
  exec "git submodule update --recursive --remote"
task build, "Build project.":
  setCommand "c"
task makecfg, "Create nim.cfg for optimized builds.":
  exec "nim utils/cfg_optimized.nims"
task clean, "Removes nim.cfg.":
  exec "nim utils/cfg_clean.nims"
