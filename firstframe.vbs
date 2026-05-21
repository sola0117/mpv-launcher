Set WShell = CreateObject("WScript.Shell")
WShell.Run "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File ""%LOCALAPPDATA%\mpv-launcher\firstframe.ps1""", 0, False
