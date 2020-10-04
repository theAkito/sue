from posix import
  getuid,
  getpwuid,
  Passwd

let
  uid = getuid()
  pwd = getpwuid(uid)

echo "NAME   :  " & $pwd.pw_name
echo "UID    :  " & $pwd.pw_uid
echo "GID    :  " & $pwd.pw_gid
echo "GECOS  :  " & $pwd.pw_gecos
echo "DIR    :  " & $pwd.pw_dir
echo "SHELL  :  " & $pwd.pw_shell