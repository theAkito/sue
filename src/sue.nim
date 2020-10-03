import
  posix,
  os,
  osproc,
  strutils

from sequtils import
  delete

if paramCount() < 3: discard # exit

# proc getgrouplist(user: cstring, group: Gid, groups: ptr array[0..255, Gid], ngroups: ptr cint): cint {.importc, header: "<grp.h>", sideEffect.}
proc getgrouplist(user: cstring, group: Gid, groups: ptr Gid, ngroups: ptr cint): cint {.importc, header: "<grp.h>", sideEffect.}
# proc setgroups(size: cint, list: ptr array[0..255, Gid]): cint {.importc, header: "<grp.h>", sideEffect.}
proc setgroups(size: cint, list: ptr Gid): cint {.importc, header: "<grp.h>", sideEffect.}

proc execvp(a1: cstring, a2: cstring): cint {.importc, header: "<unistd.h>", sideEffect.}

var
  cmd = commandLineParams()
  uid = getuid()
  gid = getgid()
  usergroup = paramStr(1)
  user: string
  group: string
  pw: ptr Passwd
  gr: ptr Group
  ngroups: cint
  glist: ptr array[0..255, Gid]
  r: cint
  zero: cint = cast[cint](0)
cmd.delete(0)
let
  ccmd = cmd.allocCStringArray()
echo uid
if usergroup.contains(":"):
  user = usergroup.split(':')[0]
  group = usergroup.split(':')[1]
  try:
    uid = user.parseUInt().Uid
  except ValueError:
    pw = getpwnam(user)
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
# glist = cast[ptr array[0..255, Gid]](gid)
# glist = addr(gid)
# echo repr(glist[0])
# echo "60: " & repr(pw)
# if pw.isNil and setgroups(1.cint, addr(gid)) < zero:
#   echo 61
#   discard # exit
# else:
#   ngroups = 0
#   let glist: ptr Gid = nil
#   while true:
#     try:
#       r = getgrouplist(pw.pw_name, gid, glist, addr(ngroups))
#     except:
#       continue
#     if r >= 0 and setgroups(ngroups, glist) < zero:
#       discard # exit
#     else: break
# if glist.isNil: echo "79: fail" # exit
if setgid(gid) < zero: echo "fail" # exit
if setuid(uid) < zero: echo "fail" # exit
echo execvp(ccmd[0], ccmd)