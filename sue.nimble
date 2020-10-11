# Package

version       = "0.2.0"
author        = "Akito <the@akito.ooo>"
description   = "Executes a program as a user different from the user running `sue`. The target program is `exec`'ed which means, that it replaces the `sue` process you are using to run the target program. This simulates native tools like `su` and `sudo` and uses the same low-level POSIX tools to achieve that, but eliminates common issues that usually arise, when using those native tools."
license       = "GPL-3.0-or-later"
srcDir        = "src"
bin           = @["sue"]
skipDirs      = @["tasks"]
skipFiles     = @["README.md"]
skipExt       = @["nim"]


# Dependencies

requires "nim >= 1.2.6"
requires "regex >= 0.16.2"


# Tasks

task test, "Run simple test.":
  "tests/".cd
  exec "nim test.nims $USER"
task xtest, "Run extended test suite. Requires Docker.":
  exec """nimble dbuild && \
          docker build \
            --no-cache \
            -t sue:test \
            -f Dockerfile \
            . && \
          docker run \
            --rm \
            -it \
            sue:test
       """
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
            --debuginfo:on \
            --out:sue \
            src/sue
       """
task makecfg, "Create nim.cfg for optimized builds.":
  exec "nim tasks/cfg_optimized.nims"
task clean, "Removes nim.cfg.":
  exec "nim tasks/cfg_clean.nims"
