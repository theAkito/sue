[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://nimble.directory/pkg/sue)

![GitHub](https://img.shields.io/badge/license-GPL--3.0-informational?style=plastic)
![Liberapay patrons](https://img.shields.io/liberapay/patrons/Akito?style=plastic)

## What
Executes a program as a user different from the user running `sue`. The target program is `exec`'ed which means, that it replaces the `sue` process you are using to run the target program. This simulates native tools like `su` and `sudo` and uses the same low-level POSIX tools to achieve that, but eliminates common issues that usually arise, when using those native tools.

## Why
Maintainable alternative to ncopa/su-exec, which is the better tianon/gosu. This one is far better (higher performance, smaller size), than the original gosu, however it is far easier to maintain, than su-exec, which is written in plain C.

This and its alternatives all exist for pretty much the same core reason:

>This is a simple tool grown out of the simple fact that `su` and `sudo` have very strange and often annoying TTY and signal-forwarding behavior.  They're also somewhat complex to setup and use (especially in the case of `sudo`), which allows for a great deal of expressivity, but falls flat if all you need is "run this specific application as this specific user and get out of the pipeline".

[Source](https://github.com/tianon/gosu/blob/master/README.md)

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
Could need some more testing and confirmation, but it works in all cases I tested so far, in a non-production environment. This will be declared stable, once it is confirmed to cover all `gosu` test cases, successfully.

## TODO
* ~~Implemente test suite~~
* Include `gosu` test cases
* Optimize
* Better error handling

## License
Copyright (C) 2020  Akito <the@akito.ooo>

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