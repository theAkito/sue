from posix import
  getuid,
  getpwuid,
  getgroups,
  Passwd,
  Gid

var
  grouplist: array[0..255, Gid]
let
  uid = getuid()
  pwd = getpwuid(uid)
  groupamount = getgroups(255, grouplist.addr)

echo "NAME   :  " & $pwd.pw_name
echo "UID    :  " & $pwd.pw_uid
echo "GID    :  " & $pwd.pw_gid
echo "GECOS  :  " & $pwd.pw_gecos
echo "DIR    :  " & $pwd.pw_dir
echo "SHELL  :  " & $pwd.pw_shell

echo "\nGroups : " & " (" & $groupamount & ") " & $grouplist.toOpenArray(0, groupamount - 1)