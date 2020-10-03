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
echo uid
if usergroup.contains(":"):
  let splitusergroup = usergroup.split(':')
  user  = splitusergroup[0]
  group = splitusergroup[1]
  try:
    uid = user.parseUInt().Uid
  except ValueError:
    pw = getpwnam(user)
else:
  user = usergroup
echo "36: " & repr(pw)
if pw.isNil:
  echo "pw is nil @ 38"
  pw = getpwuid(uid)
if pw != nil:
  uid = pw.pw_uid
  gid = pw.pw_gid
"HOME".putEnv($pw.pw_dir)
echo "43: " & repr(pw)
echo "uid: " & repr(uid)
echo "gid: " & repr(gid)
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
echo "56: " & repr(gid)
echo "57: " & repr(uid)
glist = cast[ptr array[0..255, Gid]](@[gid])
# echo "glist: " & repr(glist)
echo "60: " & repr(pw)
if pw.isNil:
  echo 61
  discard # exit
elif pw.isNil and setgroups(1.cint, glist) < zero:
  echo "89: exit"
else:
  ngroups = 0
  var glist: ptr array[0..255, Gid] = nil
  while true:
    try:
      r = getgrouplist(pw.pw_name, gid, glist, addr(ngroups))
      echo "94"
    except:
      echo "skipped"
      # continue
    if r >= 0:
      echo "99"
      break # exit
    elif r >= 0 and setgroups(ngroups, glist) < zero:
      raise Exception.newException("setgroups failed")
    else:
      glist = cast[ptr array[0..255, Gid]](realloc(glist, ngroups * sizeof(Gid)))
      if glist.isNil: echo "100: fail" # exit
if setgid(gid) < zero: echo "fail" # exit
if setuid(uid) < zero: echo "fail" # exit
echo execvp(ccmd[0], ccmd)
ccmd.deallocCStringArray
raise Exception.newException("Failed to \"exec\" " & $cmd)