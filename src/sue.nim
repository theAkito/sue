from posix import
  getuid,
  getgid,
  setuid,
  setgid,
  getpwnam,
  getpwuid,
  getgrnam,
  execvp,
  Uid,
  Gid,
  Passwd,
  Group
from os import
  getAppFilename,
  commandLineParams,
  paramStr,
  paramCount,
  putEnv
from strutils import
  split,
  contains,
  parseUInt
from regex import
  match,
  re

type POSIX_Exception = object of OSError
proc exceptPOSIX(msg: string) = raise POSIX_Exception.newException(msg)
proc usage() = echo "Usage: " & getAppFilename() & " user-spec command [args]"
proc setHomeDir(dir: string) = "HOME".putEnv(dir)
proc getgrouplist(user: cstring, group: Gid, groups: ptr array[0..255, Gid], groupamount: ptr cint): cint {.importc, header: "<grp.h>", sideEffect.}
proc setgroups(size: cint, list: ptr array[0..255, Gid]): cint {.importc, header: "<grp.h>", sideEffect.}
if paramCount() < 2: usage(); raise Exception.newException("""Invalid number of arguments.""")

var
  cmd          : seq[TaintedString] = commandLineParams()
  uid          : Uid                = getuid()
  gid          : Gid                = getgid()
  user         : string
  group        : string
  gidArray     : array[0..255, Gid]
  ptrPasswd    : ptr Passwd
  ptrGroup     : ptr Group
  ptrGidArray  : ptr array[0..255, Gid]
  groupamount  : cint
  matchedgroups: cint
cmd.delete(0)
let
  ccmd = cmd.allocCStringArray()
  usergroup = paramStr(1)

func matchNameRegex(name: string): bool =
  ## Matches username pattern as defined by `NAME_REGEX`.
  ## https://serverfault.com/a/578264/405521
  if name.match(re"^[[:alpha:]][-[:alnum:]]*$"): return true
  else: return false

proc getPasswdOrExcept(user: string) =
  ## `ptrPasswd` won't ever be `nil`.
  try:
    uid = user.parseUInt().Uid
    ptrPasswd = getpwuid(uid)
  except ValueError:
    ## If the user provided is not a numeric UID already,
    ## we will retrieve it.
    ## If provided UID is empty,
    ## get UID of the original process executor.
    if user == "": ptrPasswd = getpwuid(uid)
    elif user.matchNameRegex:
      ptrPasswd = getpwnam(user)
    else:
      exceptPOSIX("Invalid username provided.")
    if ptrPasswd.isNil:
      exceptPOSIX("Invalid username provided.")


if usergroup.contains(":"):
  let splitusergroup = usergroup.split(':')
  user  = splitusergroup[0]
  group = splitusergroup[1]
  getPasswdOrExcept(user)
else:
  getPasswdOrExcept(usergroup)

if not ptrPasswd.isNil:
  uid = ptrPasswd.pw_uid
  gid = ptrPasswd.pw_gid
  setHomeDir($ptrPasswd.pw_dir)
else:
  setHomeDir("/")

if group != "":
  ## A `group` was specified, so the automatic research
  ## for the corresponding group below is disabled.
  ptrPasswd = nil
  try:
    gid = group.parseUInt().Uid
  except ValueError:
    ## If the group provided is not a numeric GID already,
    ## the `Group` pointer for the provided group is retrieved.
    if group.matchNameRegex: 
      ptrGroup = getgrnam(group)
    else:
      exceptPOSIX("Invalid groupname provided.")
    if ptrGroup.isNil:
      exceptPOSIX("Invalid groupname provided.")
    else:
      ## The GID from the provided group is retrieved
      ## through the `Group` pointer retrieved above.
      gid = ptrGroup.gr_gid

var tgidArray: array[0..255, Gid]
tgidArray[0] = gid
if ptrPasswd.isNil:
  if setgroups(1, tgidArray.addr) < 0:
    ## Error out, if group is either not provided or not retrievable.
    exceptPOSIX("""(1) Error occured with proc "setgroups".""")
elif not ptrPasswd.isNil:
  ## If `group` wasn't specified, it will be researched.
  groupamount = 0
  ptrGidArray = nil
  while true:
    ## Retrieving amount of matching groups, until we retrieved all.
    ## Will equal `groupamount` at some point, leading to the loop's break.
    try:
      matchedgroups = getgrouplist(ptrPasswd.pw_name, gid, gidArray.addr, addr(groupamount))
    except:
      exceptPOSIX("""Error occured with proc "getgrouplist".""")
    if matchedgroups == groupamount:
      discard setgroups(groupamount, gidArray.addr)
      break

## Usually, `setgid`/`setuid` do not work, if not executed as root.
## Therefore, reminding the user to avoid the most common mistake.
if setgid(gid) < 0: exceptPOSIX("""Error occured with proc "setgid". Did you run me as the "root" user?""")
if setuid(uid) < 0: exceptPOSIX("""Error occured with proc "setuid". Did you run me as the "root" user?""")
## Either `exec`'s provided command line or echoes its error code, usually being "-1".
echo execvp(ccmd[0], ccmd)
ccmd.deallocCStringArray
## If the `exec` above failed, this program will continue, which it should not.
## Therefore, an exception is thrown, as the wished for `exec` failed.
exceptPOSIX("""Failed to `exec` """" & $cmd & """"""")