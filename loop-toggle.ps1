$pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", "mpvsocket", [System.IO.Pipes.PipeDirection]::InOut)
$pipe.Connect(1000)
$writer = New-Object System.IO.StreamWriter($pipe)
$writer.AutoFlush = $true
$writer.WriteLine('{"command": ["cycle-values", "loop-file", "inf", "no"]}')
$writer.Close()
$pipe.Close()
