Import-Module "$PSScriptRoot\mpv-ipc.psm1" -Force

Send-MpvCommand -Commands @(
    '{"command": ["seek", 0, "absolute"]}',
    '{"command": ["set_property", "pause", true]}'
)
