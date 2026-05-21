[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8


# デバイスリストを取得
$output = & mpv --audio-device=help 2>&1
$devices = $output | Where-Object { $_ -match "wasapi|openal" }

# 番号付きで表示
Write-Host ""
Write-Host "利用可能な音声デバイス:"
Write-Host ""
for ($i = 0; $i -lt $devices.Count; $i++) {
    Write-Host "$($i+1). $($devices[$i])"
}

Write-Host ""
$choice = Read-Host "番号を選択してください"
$selected = $devices[$choice - 1]

# デバイスIDを抽出
$deviceid = $selected -replace "^\s+'([^']+)'.*", '$1'

Write-Host ""
Write-Host "選択されたデバイス: $deviceid"

# mpv.confを更新
$confpath = "$env:APPDATA\mpv\mpv.conf"
$content = Get-Content $confpath
$content = $content -replace '^audio-device=.*', "audio-device=$deviceid"
Set-Content $confpath $content

Write-Host ""
Write-Host "mpv.confを更新しました: audio-device=$deviceid"
