param([string]$filePath)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
}
"@

Import-Module "$PSScriptRoot\mpv-ipc.psm1" -Force

# 設定ファイルを読み込む
$configPath = "$env:LOCALAPPDATA\mpv-launcher\config.json"
if (-not (Test-Path $configPath)) {
    Write-Error "設定ファイルが見つかりません: $configPath"
    exit 1
}

try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
}
catch {
    Write-Error "設定ファイルの読み込みに失敗しました: $_"
    exit 1
}

$mode       = $config.mode
$modeConfig = $config.$mode

if (-not $modeConfig) {
    Write-Error "モード '$mode' の設定が config.json に見つかりません"
    exit 1
}

$autoplay   = [bool]$modeConfig.autoplay
$fullscreen = [bool]$modeConfig.fullscreen
$display    = $modeConfig.display

$process = Get-Process mpv -ErrorAction SilentlyContinue

if ($process) {
    # 既存の mpv インスタンスにファイルを読み込む
    $escapedPath = $filePath.Replace('\', '\\')
    $commands    = @("{""command"": [""loadfile"", ""$escapedPath""]}")

    if (-not $autoplay) {
        # loadfile 後に mpv がファイルをロードするまで待機してから pause
        Send-MpvCommand -Commands ($commands + '{"command": ["set_property", "pause", true]}') `
                        -DelayBetweenCommandsMs 500
    }
    else {
        Send-MpvCommand -Commands $commands
    }
}
else {
    # マウスカーソルの位置を先に取得（display="current" 用）
    $cursorPos = [System.Windows.Forms.Cursor]::Position

    # mpv 起動オプションを組み立て
    $launchArgs = @(
        "--input-ipc-server=\\.\pipe\mpvsocket"
        "--keep-open=yes"
        "--loop-file=no"
        "--log-file=`"$env:LOCALAPPDATA\mpv-launcher\mpv.log`""
    )
    if (-not $autoplay) { $launchArgs += "--pause" }
    if ($fullscreen)    { $launchArgs += "--fullscreen" }
    $launchArgs += "`"$filePath`""

    Start-Process -FilePath "mpv" -ArgumentList $launchArgs

    # ウィンドウ配置先を計算
    if ($display -eq "current") {
        $screen = [System.Windows.Forms.Screen]::FromPoint($cursorPos)
        $sw     = $screen.Bounds.Width
        $sh     = $screen.Bounds.Height
        $w      = [int]($sw / 2)
        $h      = [int]($sh / 2)
        $x      = $screen.Bounds.X + [int](($sw - $w) / 2)
        $y      = $screen.Bounds.Y + [int](($sh - $h) / 2)
    }
    else {
        $screens = [System.Windows.Forms.Screen]::AllScreens
        $screen  = if ([int]$display -lt $screens.Count) { $screens[[int]$display] } else { $screens[0] }
        $x = $screen.Bounds.X
        $y = $screen.Bounds.Y
        $w = $screen.Bounds.Width
        $h = $screen.Bounds.Height
    }

    # mpv ウィンドウが表示されるまで待機（初回 250ms + 最大 1000ms ポーリング）
    Start-Sleep -Milliseconds 250
    for ($i = 0; $i -lt 10; $i++) {
        $process = Get-Process mpv -ErrorAction SilentlyContinue
        if ($process -and $process.MainWindowHandle -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 100
    }

    if ($process -and $process.MainWindowHandle -ne [IntPtr]::Zero) {
        [Win32]::MoveWindow($process.MainWindowHandle, $x, $y, $w, $h, $true)
    }
}
