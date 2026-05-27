# mpv-launcher

**Windows 専用**のランチャースクリプトです。PowerShell / Batch スクリプトで実装されており、mpv をStreamDeck やダブルクリックから操作します。

---

## 必要なもの

- [mpv](https://mpv.io/installation/) (shinchiroビルド推奨)
- Windows 10 / 11
- Stream Deck (オプション)

---

## ファイル構成

```
C:\Users\<ユーザー名>\AppData\Local\mpv-launcher\
├── mpv-launcher.ps1       # メインランチャー（動画を開く・モニター移動）
├── mpv-launcher.bat       # ダブルクリック用（ps1を呼び出す）
├── play-pause.ps1         # 再生/一時停止
├── play-pause.vbs         # StreamDeck用（play-pause.ps1を呼び出す）
├── loop-toggle.ps1        # ループON/OFF切り替え
├── loop-toggle.vbs        # StreamDeck用（loop-toggle.ps1を呼び出す）
├── firstframe.ps1         # 最初のフレームに戻る
├── firstframe.vbs         # StreamDeck用（firstframe.ps1を呼び出す）
├── mpv-ipc.psm1           # IPC通信モジュール（各スクリプトから使用）
├── set-audio-device.bat   # 音声デバイス選択
├── set-audio-device.ps1   # 音声デバイス選択（本体）
├── config.json            # 動作モード設定
└── mpv.log                # mpvログファイル（自動生成）

%APPDATA%\mpv\
└── mpv.conf               # mpv設定ファイル
```

---

## mpv.conf

mpv.confに設定するのは以下の2項目のみにしてください。

```ini
input-ipc-server=\\.\pipe\mpvsocket          # IPC設定（StreamDeck・コントロールパネル連携用）
audio-device=wasapi/{デバイスID}             # 音声出力デバイス
```

> **注意**: `pause` / `keep-open` / `loop-file` / `fullscreen` / `screen` などをmpv.confに設定すると、ランチャーの動作を上書きしてしまいます。
> 特に `pause`（autoplay）・`fullscreen`・`screen`（display）はconfig.jsonで制御しているため、mpv.confには記述しないでください。

---

## config.json

PCごとに動作モードを設定します。`mode`の値を変更してモードを切り替えてください。

```json
{
    "mode": "playback",
    "playback": {
        "fullscreen": true,
        "display": 1,
        "autoplay": false
    },
    "preview": {
        "fullscreen": false,
        "display": "current",
        "autoplay": true
    }
}
```

### モード一覧

| モード | 説明 |
|--------|------|
| `playback` | プレイバック用。全画面・指定モニター固定・最初のフレームで停止 |
| `preview` | 再生用。ウィンドウ（モニターの50%サイズ・中央）・ダブルクリックしたディスプレイ・即時再生 |

### display設定

| 値 | 説明 |
|----|------|
| `0` | プライマリモニター |
| `1` | 2番目のモニター |
| `2` | 3番目のモニター |
| `"current"` | ダブルクリック時のマウスカーソルがあるディスプレイ |

接続されているモニターの番号は以下のコマンドで確認できます：

```powershell
Add-Type -AssemblyName System.Windows.Forms
$i = 0
[System.Windows.Forms.Screen]::AllScreens | ForEach-Object {
    Write-Output "$i. $($_.DeviceName) $($_.Bounds) Primary=$($_.Primary)"
    $i++
}
```

---

## インストール手順

### 1. mpvのインストール

```powershell
winget install shinchiro.mpv
```

PATHを通す：

```powershell
[System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\MPV Player", [System.EnvironmentVariableTarget]::Machine)
```

### 2. mpv.confの作成

```powershell
mkdir "$env:APPDATA\mpv"
notepad "$env:APPDATA\mpv\mpv.conf"
```

### 3. ランチャーフォルダの作成

```powershell
mkdir "$env:LOCALAPPDATA\mpv-launcher"
```

### 4. 音声デバイスの設定

`set-audio-device.bat`を実行して音声デバイスを選択してください。

---

## ダブルクリックで動画を開く設定

1. 動画ファイルを右クリック
2. 「プログラムから開く」→「別のプログラムを選択」
3. `mpv-launcher.bat`を選択
4. 「常にこのアプリを使って開く」にチェックを入れてOK

---

## StreamDeck設定

各ボタンに「システム: 開く」アクションを追加して以下のファイルを指定してください。

| ボタン | ファイル |
|--------|---------|
| 再生/停止 | `play-pause.vbs` |
| ループON/OFF | `loop-toggle.vbs` |
| 最初のフレームに戻る | `firstframe.vbs` |

---

## 動作仕様

### モード別動作

#### playbackモード
- 全画面で起動
- `display`で指定したモニターに表示
- ファイルを開いたときに最初のフレームで停止

#### previewモード
- ウィンドウモードで起動（モニターサイズの50%・中央配置）
- ダブルクリック時のマウスカーソルがあるディスプレイに表示
- ファイルを開いたら即時再生

### 複数ファイルの再生
- mpvが起動していない場合 → 新規ウィンドウで開く
- mpvがすでに起動している場合 → 同じウィンドウで新しいファイルを読み込む

### IPC通信
WindowsではIPCに名前付きパイプを使用しています。

```
\\.\pipe\mpvsocket
```

---

## トラブルシューティング

### 音声が出ない
`set-audio-device.bat`を再実行して音声デバイスを再設定してください。

### 接続中のモニター番号を確認したい

```powershell
Add-Type -AssemblyName System.Windows.Forms
$i = 0
[System.Windows.Forms.Screen]::AllScreens | ForEach-Object {
    Write-Output "$i. $($_.DeviceName) $($_.Bounds) Primary=$($_.Primary)"
    $i++
}
```

### ウィンドウが指定したモニターに移動しない
`config.json`の`display`番号が正しいか確認してください。

### IPCが接続できない
mpvが起動しているか確認してください。mpvを再起動するとIPCソケットが再生成されます。

### エラーメッセージが文字化けする
Windows PowerShell 5.x はBOMなしUTF-8を正しく認識しないことがあります。各スクリプトファイルを **UTF-8 with BOM** で保存し直してください。

VS Code の場合：エディタ右下のエンコーディング表示をクリック →「エンコード付きで保存」→「UTF-8 with BOM」を選択。