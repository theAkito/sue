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
  cmd = commandLineParams()
  uid = getuid()
  gid = getgid()
  user: string
  group: string
  pw: ptr Passwd
  gr: ptr Group
  groupamount: cint
  grouplist: ptr array[0..255, Gid]
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
    pw = getpwnam(user)
elif not usergroup.contains(":"):
  try:
    uid = usergroup.parseUInt().Uid
  except ValueError:
    pw = getpwnam(usergroup)
    if pw.isNil:
      exceptPOSIX("""Invalid username provided.""")

if not pw.isNil:
  uid = pw.pw_uid
  gid = pw.pw_gid
  "HOME".putEnv($pw.pw_dir)
else:
  "HOME".putEnv("/")

if group != "":
  pw = nil
  try:
    gid = group.parseUInt().Uid
  except ValueError:
    gr = getgrnam(group)
    if gr.isNil:
      discard # exit
    else:
      gid = gr.gr_gid

grouplist = cast[ptr array[0..255, Gid]](@[gid])
if pw.isNil: discard
elif pw.isNil and setgroups(1.cint, grouplist) < zero:
  exceptPOSIX("""Error occured with proc "setgroups".""")
else:
  groupamount = 0
  grouplist = nil
  while true:
    try:
      matchedgroups = getgrouplist(pw.pw_name, gid, grouplist, addr(groupamount))
    except:
      exceptPOSIX("""Error occured with proc "getgrouplist".""")
    if matchedgroups >= 0: break
    elif matchedgroups >= 0 and setgroups(groupamount, grouplist) < zero:
      exceptPOSIX("""Error occured with proc "setgroups".""")
    else:
      grouplist = cast[ptr array[0..255, Gid]](realloc(grouplist, groupamount * sizeof(Gid)))
      if grouplist.isNil:
        exceptPOSIX("List of groups may not be empty.")

if setgid(gid) < zero: exceptPOSIX("""Error occured with proc "setgid".""")
if setuid(uid) < zero: exceptPOSIX("""Error occured with proc "setuid".""")
echo execvp(ccmd[0], ccmd)
ccmd.deallocCStringArray
exceptPOSIX("""Failed to "exec" """" & $cmd & """"""")