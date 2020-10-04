#!/usr/bin/env nim
mode = ScriptMode.Silent
switch("hints", "off")

exec "nim c whoami" 
"../".cd
exec "nimble dbuild"
exec "sudo ./sue " & paramStr(2) & " ./tests/whoami"
"./tests/whoami".rmFile
"./sue".rmFile