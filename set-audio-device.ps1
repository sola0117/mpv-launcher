[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# デバイスリストを取得
$output  = & mpv --audio-device=help 2>&1
$devices = $output | Where-Object { $_ -match "wasapi|openal" }

if ($devices.Count -eq 0) {
    Write-Host "利用可能な音声デバイスが見つかりませんでした。mpv が正しくインストールされているか確認してください。"
    exit 1
}

# 番号付きで表示
Write-Host ""
Write-Host "利用可能な音声デバイス:"
Write-Host ""
for ($i = 0; $i -lt $devices.Count; $i++) {
    Write-Host "$($i + 1). $($devices[$i])"
}

Write-Host ""
$choice = Read-Host "番号を選択してください (1-$($devices.Count))"

# 入力バリデーション
if ($choice -notmatch '^\d+$' -or [int]$choice -lt 1 -or [int]$choice -gt $devices.Count) {
    Write-Host "無効な入力です。1〜$($devices.Count) の番号を入力してください。"
    exit 1
}

$selected = $devices[[int]$choice - 1]

# デバイスIDを抽出
$deviceId = $selected -replace "^\s+'([^']+)'.*", '$1'

Write-Host ""
Write-Host "選択されたデバイス: $deviceId"

# mpv.conf を更新
$confPath = "$env:APPDATA\mpv\mpv.conf"
if (-not (Test-Path $confPath)) {
    Write-Host "mpv.conf が見つかりません: $confPath"
    Write-Host "先に mpv.conf を作成して audio-device= の行を追加してください。"
    exit 1
}

$content = Get-Content $confPath
if ($content -match '^audio-device=') {
    $content = $content -replace '^audio-device=.*', "audio-device=$deviceId"
}
else {
    $content += "audio-device=$deviceId"
}
Set-Content $confPath $content

Write-Host ""
Write-Host "mpv.conf を更新しました: audio-device=$deviceId"
