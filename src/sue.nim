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
  commandLineParams,
  paramStr,
  paramCount,
  putEnv
from strutils import
  split,
  contains,
  parseUInt

type
  POSIX_Exception = object of OSError

if paramCount() < 3: discard # exit

proc getgrouplist(user: cstring, group: Gid, groups: ptr array[0..255, Gid], ngroups: ptr cint): cint {.importc, header: "<grp.h>", sideEffect.}
proc setgroups(size: cint, list: ptr array[0..255, Gid]): cint {.importc, header: "<grp.h>", sideEffect.}

var
  cmd = commandLineParams()
  uid = getuid()
  gid = getgid()
  user: string
  group: string
  pw: ptr Passwd
  gr: ptr Group
  ngroups: cint
  glist: ptr array[0..255, Gid]
  r: cint
cmd.delete(0)
let
  ccmd = cmd.allocCStringArray()
  usergroup = paramStr(1)
const
  zero: cint = cast[cint](0)
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
      raise POSIX_Exception.newException("""Invalid username provided.""")
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
glist = cast[ptr array[0..255, Gid]](@[gid])
if pw.isNil: discard
elif pw.isNil and setgroups(1.cint, glist) < zero:
  raise POSIX_Exception.newException("""Error occured with proc "setgroups".""")
else:
  ngroups = 0
  var glist: ptr array[0..255, Gid] = nil
  while true:
    try:
      r = getgrouplist(pw.pw_name, gid, glist, addr(ngroups))
    except:
      raise POSIX_Exception.newException("""Error occured with proc "getgrouplist".""")
    if r >= 0: break
    elif r >= 0 and setgroups(ngroups, glist) < zero:
      raise POSIX_Exception.newException("""Error occured with proc "setgroups".""")
    else:
      glist = cast[ptr array[0..255, Gid]](realloc(glist, ngroups * sizeof(Gid)))
      if glist.isNil: echo "100: fail" # exit
if setgid(gid) < zero: echo "fail" # exit
if setuid(uid) < zero: echo "fail" # exit
echo execvp(ccmd[0], ccmd)
ccmd.deallocCStringArray
raise POSIX_Exception.newException("Failed to \"exec\" " & $cmd)