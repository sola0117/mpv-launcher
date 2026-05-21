$pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", "mpvsocket", [System.IO.Pipes.PipeDirection]::Out)
$pipe.Connect(1000)
$writer = New-Object System.IO.StreamWriter($pipe)
$writer.AutoFlush = $true
$writer.WriteLine('{"command": ["seek", 0, "absolute"]}')
$writer.WriteLine('{"command": ["set_property", "pause", true]}')
$writer.Close()
$pipe.Close()
