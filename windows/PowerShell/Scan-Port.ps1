function Scan-port {
    Param(
        [Parameter(Mandatory=$true)]
        $iplist,
        [Parameter(Mandatory=$true)]
        $port
    )
    foreach ($ip in $iplist){
        $sb = [scriptblock]::Create("try {`$tcpclient = New-Object System.Net.Sockets.TcpClient;`$tcpclient.ReceiveTimeout = 10;`$tcpclient.connect(`"$ip`",$port);if (`$tcpclient.Connected){`$tcpclient.Dispose();`"$ip`"}} catch {`$tcpclient.Dispose()}")
        $a = Start-Job -ScriptBlock $sb
    }
    while (Get-Job -State Running){
        sleep 3
        plus;Write-Host "waiting for winRM results to return..." -ForegroundColor Green
    }
    $results = Get-Job -State Completed | Receive-Job
    Get-job | Remove-job
    return $results
}
