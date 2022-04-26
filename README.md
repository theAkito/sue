[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://nimble.directory/pkg/sue)

[![Source](https://img.shields.io/badge/project-source-2a2f33?style=plastic)](https://github.com/theAkito/sue)
[![Language](https://img.shields.io/badge/language-Nim-orange.svg?style=plastic)](https://nim-lang.org/)

![Last Commit](https://img.shields.io/github/last-commit/theAkito/sue?style=plastic)

[![GitHub](https://img.shields.io/badge/license-GPL--3.0-informational?style=plastic)](https://www.gnu.org/licenses/gpl-3.0.txt)
[![Liberapay patrons](https://img.shields.io/liberapay/patrons/Akito?style=plastic)](https://liberapay.com/Akito/)

## What
Executes a program as a user different from the user running `sue`. The target program is `exec`'ed which means, that it replaces the `sue` process you are using to run the target program. This simulates native tools like `su` and `sudo` and uses the same low-level POSIX tools to achieve that, but eliminates common issues that usually arise, when using those native tools.

## Why
As small and swift as `su-exec`, but as featureful and robust as `gosu`!

This and its alternatives all exist for pretty much the same core reason:

>This is a simple tool grown out of the simple fact that `su` and `sudo` have very strange and often annoying TTY and signal-forwarding behavior.  They're also somewhat complex to setup and use (especially in the case of `sudo`), which allows for a great deal of expressivity, but falls flat if all you need is "run this specific application as this specific user and get out of the pipeline".

[Source](https://github.com/tianon/gosu/blob/master/README.md)

### Why use `sue` instead of `su-exec`, `gosu` or other alternatives?
An opinionated comparison!

**Better than `gosu` in these ways:**

`gosu` is written in Go, which is comparatively slow and bloated compared to other systems programming languages. `sue` is written in [Nim](https://nim-lang.org/), which is comparable to C in terms of performance and size, while being actually maintainable & readable.

**Better than `su-exec` in these ways:**

`su-exec` is supposed to be a far more lightweight alternative to `gosu`. As an example, the official Debian-based `postgres` images use `gosu` while the Alpine-based images use `su-exec`.
The latter is written in C, meaning that the level of maintainability is kept pretty low. It also is focused entirely on size and less on providing every feature of `gosu` in a more compact fashion. `gosu` has a stricter and much more robust behaviour, than `su-exec`.

`sue` is on the other hand covering all `gosu` test cases, meaning that it provides precisely the same feature set as `gosu` while being only half the size and most likely being also more performant overall.

**Better than `chroot` in these ways:**

`chroot` is a bit clunky and not as straight-forward to use. For the use-case of the specific privilege management in Docker environments, this tool is not well suited, as it has originally a different overall purpose.

**Better than `setpriv` in these ways:**

Similar to `chroot`, `setpriv` feels very clunky and you have to provide so much information explicitly, when it could be so much more straight-forward and easy to use, as is `gosu`, `su-exec` or `sue`.

## How
First, make sure you are running `sue` as the `root` user, to avoid permission issues.

Get the project and prepare it:
```
git clone https://github.com/theAkito/sue.git
cd sue
nimble configure
```
To build the project use one of the predefined tasks:
```
nimble fbuild
```
for the release build or
```
nimble dbuild
```
for the debug/development build.

You can also make a quick test if `sue` works, as it should:
```
nimble test
```
Run the fully fledged test suite, covering a large amount of edge cases and possible flukes:
```
nimble xtest
```
This test suite covers all original [`gosu` test cases](https://github.com/tianon/gosu/blob/master/Dockerfile.test-alpine). Since all are passed successfully, we achieve full compatability with `gosu`'s behaviour.
____

The first argument passed to `sue` is the *user-spec* with either the username or its `id`. Appending a `group` to the *user-spec* is optional.

The following examples assume a user named *dunwall*, belonging to a group of the same name and `id`.

Example 1:
```bash
./sue dunwall src/test
```
Example 2:
```bash
./sue dunwall:dunwall src/test
```
Example 3:
```bash
./sue 1000:dunwall src/test
```

## Where
This tool is meant to be used in a Docker environment, as a way to execute a program while temporarily switching the user just for running that process, as some need to be run as a specific user or need a designated user for taking over a user role in that program.

### Real world example

The following example is taken from the official `postgres:13-alpine` Docker image's `docker-entrypoint.sh` script, where `su-exec` is used to execute this startup script as the `postgres` user, since PostgreSQL should be operated by the `postgres` user.

```bash
	if [ "$1" = 'postgres' ] && ! _pg_want_help "$@"; then
		docker_setup_env
		# setup data directories and permissions (when run as root)
		docker_create_db_directories
		if [ "$(id -u)" = '0' ]; then
			# then restart script as postgres user
			exec su-exec postgres "$BASH_SOURCE" "$@"
		fi
```

[Source](https://github.com/docker-library/postgres/blob/b80fcb5ac7f6dde712e70d2d53a88bf880700fde/13/docker-entrypoint.sh#L281)

Note that use-cases like this one are the primary target of `sue`. Using this program outside of a Docker container usually means that this tool is misused, as it is specifically designed for the type of purpose shown in the example above.

## Goals
* Performance
* Size
* Maintainability

## Project Status
All [`gosu` test cases](https://github.com/tianon/gosu/blob/master/Dockerfile.test-alpine) are covered, achieving full compatability with `gosu`'s behaviour. Therefore, this alternative is just as stable as the widely popular `gosu`.

## TODO
* ~~Implement test suite~~
* ~~Include `gosu` test cases~~
* ~~Better error handling~~
* Add base Docker image
* Add CI
* Separate inlined script from Dockerfile
* Optimize

## License
Copyright © 2020-2022  Akito <the@akito.ooo>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.