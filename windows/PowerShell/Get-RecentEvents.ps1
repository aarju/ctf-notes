Get-WinEvent -ListLog * -EA silentlycontinue | where-object { $_.recordcount -AND $_.lastwritetime
 -gt (Get-Date).AddMinutes(-10)} | foreach-object { get-winevent -LogName $_.logname -MaxEvents 1 }
