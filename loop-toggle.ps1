Import-Module "$PSScriptRoot\mpv-ipc.psm1" -Force

Send-MpvCommand -Commands '{"command": ["cycle-values", "loop-file", "inf", "no"]}'
