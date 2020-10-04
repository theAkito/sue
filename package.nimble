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

requires "nim >= 1.2.6"


# Tasks

task test, "Run test.":
  exec "nim cc -r tests/test.nim"
task configure, "Configure project.":
  exec "git fetch"
  exec "git pull"
  exec "git checkout master"
  exec "git submodule add git@github.com:theAkito/nim-tools.git tasks"
  exec "git submodule update --init --recursive"
  exec "git submodule update --recursive --remote"
task fbuild, "Build project.":
  exec """nim c \
            --define:danger \
            --opt:size \
            --out:sue \
            src/sue
       """
task dbuild, "Debug Build project.":
  exec """nim c \
            --out:sue \
            --debuginfo:on \
            src/sue
       """
task makecfg, "Create nim.cfg for optimized builds.":
  exec "nim utils/cfg_optimized.nims"
task clean, "Removes nim.cfg.":
  exec "nim utils/cfg_clean.nims"
