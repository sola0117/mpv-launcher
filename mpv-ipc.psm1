<#
.SYNOPSIS
    mpv IPC（名前付きパイプ）通信モジュール

.DESCRIPTION
    mpvへのIPC通信を抽象化したモジュールです。
    各コントロールスクリプトから Import-Module して使用します。
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

$Script:PipeName       = "mpvsocket"
$Script:ConnectTimeout = 1000   # ms

<#
.SYNOPSIS
    mpvにIPCコマンドを送信します。

.PARAMETER Commands
    送信するJSONコマンド文字列の配列。

.PARAMETER DelayBetweenCommandsMs
    コマンド間の待機時間（ミリ秒）。デフォルトは 0（待機なし）。

.PARAMETER TimeoutMs
    パイプ接続タイムアウト（ミリ秒）。デフォルトは 1000ms。

.OUTPUTS
    成功時は $true、失敗時は $false。
#>
function Send-MpvCommand {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string[]]$Commands,

        [int]$DelayBetweenCommandsMs = 0,

        [int]$TimeoutMs = $Script:ConnectTimeout
    )

    $pipe   = $null
    $writer = $null
    try {
        $pipe = New-Object System.IO.Pipes.NamedPipeClientStream(
            ".", $Script:PipeName,
            [System.IO.Pipes.PipeDirection]::InOut
        )
        $pipe.Connect($TimeoutMs)

        $writer           = New-Object System.IO.StreamWriter($pipe)
        $writer.AutoFlush = $true

        for ($i = 0; $i -lt $Commands.Count; $i++) {
            if ($i -gt 0 -and $DelayBetweenCommandsMs -gt 0) {
                Start-Sleep -Milliseconds $DelayBetweenCommandsMs
            }
            $writer.WriteLine($Commands[$i])
        }
        return $true
    }
    catch {
        Write-Warning "mpvへのIPC接続に失敗しました: $_"
        return $false
    }
    finally {
        if ($writer) { $writer.Close() }
        if ($pipe)   { $pipe.Close()   }
    }
}

Export-ModuleMember -Function Send-MpvCommand
