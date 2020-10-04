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
const
  zero: cint = 0

if usergroup.contains(":"):
  let splitusergroup = usergroup.split(':')
  user  = splitusergroup[0]
  group = splitusergroup[1]
  try:
    uid = user.parseUInt().Uid
  except ValueError:
    ptrPasswd = getpwnam(user)
elif not usergroup.contains(":"):
  try:
    uid = usergroup.parseUInt().Uid
  except ValueError:
    ptrPasswd = getpwnam(usergroup)
    if ptrPasswd.isNil:
      exceptPOSIX("""Invalid username provided.""")

if not ptrPasswd.isNil:
  uid = ptrPasswd.pw_uid
  gid = ptrPasswd.pw_gid
  "HOME".putEnv($ptrPasswd.pw_dir)
else:
  "HOME".putEnv("/")

if group != "":
  ptrPasswd = nil
  try:
    gid = group.parseUInt().Uid
  except ValueError:
    ptrGroup = getgrnam(group)
    if ptrGroup.isNil:
      exceptPOSIX("""Error occured with proc "getgrnam".""")
    else:
      gid = ptrGroup.gr_gid

ptrGidArray = cast[ptr array[0..255, Gid]](@[gid])
if ptrPasswd.isNil: discard
elif ptrPasswd.isNil and setgroups(1.cint, ptrGidArray) < zero:
  exceptPOSIX("""Error occured with proc "setgroups".""")
else:
  groupamount = 0
  ptrGidArray = nil
  while true:
    try:
      matchedgroups = getgrouplist(ptrPasswd.pw_name, gid, ptrGidArray, addr(groupamount))
    except:
      exceptPOSIX("""Error occured with proc "getgrouplist".""")
    if matchedgroups >= 0: break
    elif matchedgroups >= 0 and setgroups(groupamount, ptrGidArray) < zero:
      exceptPOSIX("""Error occured with proc "setgroups".""")
    else:
      ptrGidArray = cast[ptr array[0..255, Gid]](realloc(ptrGidArray, groupamount * sizeof(Gid)))
      if ptrGidArray.isNil:
        exceptPOSIX("List of groups may not be empty.")

if setgid(gid) < zero: exceptPOSIX("""Error occured with proc "setgid". Did you run me as the "root" user?""")
if setuid(uid) < zero: exceptPOSIX("""Error occured with proc "setuid". Did you run me as the "root" user?""")
echo execvp(ccmd[0], ccmd)
ccmd.deallocCStringArray
exceptPOSIX("""Failed to "exec" """" & $cmd & """"""")