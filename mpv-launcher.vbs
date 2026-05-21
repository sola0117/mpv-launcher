Dim filePath
filePath = WScript.Arguments(0)

Dim WShell
Set WShell = CreateObject("WScript.Shell")
WShell.Run "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & "%LOCALAPPDATA%\mpv-launcher\mpv-launcher.ps1" & """ """ & filePath & """", 0, False