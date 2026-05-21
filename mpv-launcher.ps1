param([string]$filePath)

Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
}
"@

# 設定ファイルを読み込む
$config = Get-Content "$env:LOCALAPPDATA\mpv-launcher\config.json" | ConvertFrom-Json
$mode = $config.mode
$modeConfig = $config.$mode

$autoplay = $modeConfig.autoplay
$fullscreen = $modeConfig.fullscreen
$display = $modeConfig.display

# mpvの起動オプションを組み立て
$pauseOption = if ($autoplay) { "" } else { "--pause" }
$fullscreenOption = if ($fullscreen) { "--fullscreen" } else { "" }

$process = Get-Process mpv -ErrorAction SilentlyContinue

if ($process) {
    $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", "mpvsocket", [System.IO.Pipes.PipeDirection]::InOut)
    $pipe.Connect(1000)
    $writer = New-Object System.IO.StreamWriter($pipe)
    $writer.AutoFlush = $true
    $filePath = $filePath.Replace('\', '\\')
    $writer.WriteLine("{""command"": [""loadfile"", ""$filePath""]}")
    if (-not $autoplay) {
        Start-Sleep -Milliseconds 500
        $writer.WriteLine('{"command": ["set_property", "pause", true]}')
    }
    $writer.Close()
    $pipe.Close()
} else {
    # マウスカーソルの位置を先に取得
    $cursorPos = [System.Windows.Forms.Cursor]::Position

    Start-Process -FilePath "mpv" -ArgumentList "--input-ipc-server=\\.\pipe\mpvsocket $pauseOption $fullscreenOption --keep-open=yes --loop-file=no --log-file=`"$env:LOCALAPPDATA\mpv-launcher\mpv.log`" `"$filePath`""

    if ($display -eq "current") {
        $screen = [System.Windows.Forms.Screen]::FromPoint($cursorPos)
        $sw = $screen.Bounds.Width
        $sh = $screen.Bounds.Height
        $w = $sw / 2
        $h = $sh / 2
        $x = $screen.Bounds.X + ($sw - $w) / 2
        $y = $screen.Bounds.Y + ($sh - $h) / 2
    } else {
        $screens = [System.Windows.Forms.Screen]::AllScreens
        $screen = if ($display -lt $screens.Count) { $screens[$display] } else { $screens[0] }
        $x = $screen.Bounds.X
        $y = $screen.Bounds.Y
        $w = $screen.Bounds.Width
        $h = $screen.Bounds.Height
    }

    # 250ms待機してからウィンドウ検索開始
    Start-Sleep -Milliseconds 250

    $maxAttempts = 10
    $attempt = 0
    $process = $null

    while ($attempt -lt $maxAttempts) {
        $process = Get-Process mpv -ErrorAction SilentlyContinue
        if ($process -and $process.MainWindowHandle -ne 0) {
            break
        }
        Start-Sleep -Milliseconds 100
        $attempt++
    }

    if ($process -and $process.MainWindowHandle -ne 0) {
        [Win32]::MoveWindow($process.MainWindowHandle, $x, $y, $w, $h, $true)
    }
}