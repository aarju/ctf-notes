Function Get-Uptime {
    <#
    .Synopsis
    Returns the uptime in seconds of a host.
    
    #>
    Param(
        [Parameter(Mandatory=$false, Position=1)]
        [string]$computer
    )
    if ($computer){
        $uptime = (Get-WmiObject Win32_PerfFormattedData_PerfOS_System -ComputerName $computer).SystemUpTime
    } else {
        $uptime = (Get-WmiObject Win32_PerfFormattedData_PerfOS_System).SystemUpTime
    }
    return $uptime
}
