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

type POSIX_Exception = object of OSError
proc exceptPOSIX(msg: string) = raise POSIX_Exception.newException(msg)
proc usage() = echo "Usage: " & getAppFilename() & " user-spec command [args]"
proc setHomeDir(dir: string) = "HOME".putEnv(dir)
proc getgrouplist(user: cstring, group: Gid, groups: ptr array[0..255, Gid], groupamount: ptr cint): cint {.importc, header: "<grp.h>", sideEffect.}
proc setgroups(size: cint, list: ptr array[0..255, Gid]): cint {.importc, header: "<grp.h>", sideEffect.}
if paramCount() < 2: usage(); raise Exception.newException("""Invalid number of arguments.""")

var
  cmd: seq[TaintedString] = commandLineParams()
  uid: Uid = getuid()
  gid: Gid = getgid()
  user: string
  group: string
  ptrPasswd: ptr Passwd
  ptrGroup: ptr Group
  ptrGidArray: ptr array[0..255, Gid]
  groupamount: cint
  matchedgroups: cint
cmd.delete(0)
let
  ccmd = cmd.allocCStringArray()
  usergroup = paramStr(1)

proc getUIDorExcept(user: string) =
  try:
    uid = user.parseUInt().Uid
  except ValueError:
    ## If the user provided is not a numeric UID already,
    ## we will retrieve it.
    ptrPasswd = getpwnam(user)
    ## Error out on invalid username.
    if ptrPasswd.isNil:
      exceptPOSIX("""Invalid username provided.""")

if usergroup.contains(":"):
  let splitusergroup = usergroup.split(':')
  user  = splitusergroup[0]
  group = splitusergroup[1]
  getUIDorExcept(user)
elif not usergroup.contains(":"):
  getUIDorExcept(usergroup)

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
    ptrGroup = getgrnam(group)
    if ptrGroup.isNil:
      exceptPOSIX("""Error occured with proc "getgrnam".""")
    else:
      ## The GID from the provided group is retrieved
      ## through the `Group` pointer retrieved above.
      gid = ptrGroup.gr_gid

ptrGidArray = cast[ptr array[0..255, Gid]](@[gid])
if ptrPasswd.isNil and setgroups(1, ptrGidArray) < 0:
  ## Error out, if group is either not provided or not retrievable.
  exceptPOSIX("""Error occured with proc "setgroups".""")
elif not ptrPasswd.isNil:
  ## If `group` wasn't specified, it will be researched.
  groupamount = 0
  ptrGidArray = nil
  while true:
    ## Retrieving amount of matching groups, until we retrieved all.
    ## Will equal `groupamount` at some point, leading to the loop's break.
    try:
      matchedgroups = getgrouplist(ptrPasswd.pw_name, gid, ptrGidArray, addr(groupamount))
    except:
      exceptPOSIX("""Error occured with proc "getgrouplist".""")
    if matchedgroups >= 0: break
    elif matchedgroups >= 0 and setgroups(groupamount, ptrGidArray) < 0:
      ## Sets `matchedgroups`, i.e. the list of retrieved GIDs, for this process.
      ## Errors out, if `setgroups` failed.
      exceptPOSIX("""Error occured with proc "setgroups".""")
    else:
      ## Resizes the list of GIDs, as more are to be retrieved through this loop.
      ptrGidArray = cast[ptr array[0..255, Gid]](realloc(ptrGidArray, groupamount * sizeof(Gid)))
      if ptrGidArray.isNil:
        exceptPOSIX("""List "ptrGidArray" may not be nil.""")

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