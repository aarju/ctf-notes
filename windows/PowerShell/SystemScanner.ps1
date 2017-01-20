<#
    
    .Synopsis
    This is the primary SystemScanner script file. It runs the menu system and calls all other modules.

    .Description
    This script uses a menu driven system for an administrator to conduct scans against a collection of hosts on a domain.
    This script requires the PSSurvey.ps1 script to be in the current directory so that it can be loaded and executed on the remote host.

    .Usage
    powershell.exe -exec bypass systemscanner.ps1

    .Author
    Aaron Jewitt
    Aaron.c.jewitt.ctr@mail.mil
    RCC-E

#>


# functions for making colorful little ascii symbols
function Plus {Write-Host "[+] " -f green -NoNewline;}
function Minus {Write-Host "[-] " -f red -NoNewline;}
function Equals {Write-Host "[=] " -f Yellow -NoNewline;}

# these are used when you do a Yes/No/Cancel prompt for the user
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Description."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Description."
$cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel","Description."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $cancel)
        <#
        This is the code for adding a prompt to a script

        $title = "This is the prompt Title"
        $message = "Question?"

        $result = $host.ui.PromptForChoice($title, $message, $options, 1)
        switch ($result) {
            0{
                Write-Host "Yes"
            }1{
                Write-Host "No"
            }2{
                Write-Host "Cancel"
            }
        }
        #>

function grep {
  $input | out-string -stream | select-string $args
}

Function Invoke-SystemScanner {
    # runs the startup checks and then calls the start-menu function
    if ($projectpath = Invoke-startupChecks){ # runs the startup checks and gets the project path
        Invoke-ScanningMenu -projectpath $projectpath  
    } else {
        minus;Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
        minus;Write-Host "Something went wrong with the startup checks" -ForegroundColor Red
        minus;Write-Host "Check the errors above to see what went wrong" -ForegroundColor Red
        minus;Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
    }
}


function Invoke-startupChecks {
    $console = $host.ui.RawUI
    $console.ForegroundColor = "white"
    $console.BackgroundColor = "black"
    $buffer = $console.BufferSize
    $buffer.Width = 130
    $buffer.Height = 9999
    $console.BufferSize = $buffer
    $size = $console.WindowSize
    $size.Width = 130
    $size.Height = 50
    $console.WindowSize = $size
    Clear-Host 
    plus; Write-Host "Executing startup checks" -ForegroundColor White
    # get the working directory 
    if ($projectpath = Get-ProjectDirectory){
        plus; Write-Host "Created $projectpath"
    } else {
        Minus; Write-Host "Failed to create the Project Path" -ForegroundColor Red
        return $false
    }
    if (Test-Path .\PSSurvey.ps1){
        return $projectpath
    } else {
        minus; Write-Host "Unable to find the .PSSurvey.ps1 file. Make sure it is in the same directory as SystemScanner.ps1" -ForegroundColor Red
        return $false
    }   
}

Function Get-ProjectDirectory{
    # get the working directory of the project
    # get the name of the project
    plus; Write-Host "The current directory is " $PWD
    equals; $project = Read-Host "Enter the name of the Project"
    plus; Write-Host "Creating the project working directory"
    $title = ""
    $message = "Do you want to use $pwd\$project as your project directory?"

    $result = $host.ui.PromptForChoice($title, $message, $options, 0)
    switch ($result) {
        0{
            $path = "$pwd\$project"
            plus; Write-Host "Using $path as the project directory"
        }1{
            plus; $path = read-Host "Enter the full path of the project directory"
            plus; Write-Host "Using $path as the project directory"
        }2{
            minus; Write-Host "Exiting"
            return $false
        }
    }
    $newpath = New-Item $path -ItemType Directory -Force
    return ($newpath).Fullname
}

Function Invoke-ScanningMenu {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string]$projectpath
    )
    do {
    plus;write-host "------------------------------------------------------------------------" -ForegroundColor green
    plus;Write-Host "-                       Scanning Host Selection Menu                   -" -ForegroundColor green
    plus;Write-Host "------------------------------------------------------------------------" -ForegroundColor green
    plus;Write-Host ""
    plus;Write-Host "Output files will be written to $projectpath"
    plus;Write-Host "Any existing PowerShell Sessions or Jobs will be deleted. Exit now if you don't want that" 
    plus;Write-Host ""
    plus;Write-Host "Please Select how you will select hosts to scan:"
    plus;write-host "-----------------------------------------------"
    plus;write-host "1. Scan a single IP or hostname"
    plus;write-host "2. Scan a subnet or range of IPs"
    plus;write-host "3. Scan a list of IPs from a hostfile"
    plus;write-host "4. Scan an OU (not implemented yet)" -ForegroundColor DarkGray
    plus;write-host "5. EXIT"   
    equals;$answer = Read-Host "Enter your selection"
    switch ($answer){
        "1" {
                #TODO accept CIDR format
                Scan-IPAddress -projectpath $projectpath
            } 
        "2" {
                Get-Subnet -projectpath $projectpath
            }
        "3" {
                Get-Hostfile -projectpath $projectpath
            }

        "4" {Get-OU -projectpath $projectpath}
        "5" {
                minus;Write-Host "Exiting Scan Module" -ForegroundColor yellow
                return
            }
        default {
                minus;Write-Host "You didn't make a valid choice" -ForegroundColor Yellow
            }
        }
    } While ($true)
}

function Get-OU {
    minus;Write-Host "This function not yet implmented" -ForegroundColor Red
}

function Get-IPrange {
    <#
        
      .SYNOPSIS  
        Parses a CIDR or range of IP addresses and returns an array with each individual IP
      .EXAMPLE 
       Get-IPrange -start 192.168.8.2 -end 192.168.8.20 
      .EXAMPLE 
       Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0 
      .EXAMPLE 
       Get-IPrange -ip 192.168.8.3 -cidr 24 
    #> 
    param 
    ( 
          [string]$start, 
          [string]$end, 
          [string]$ip, 
          [string]$mask, 
          [int]$cidr 
    ) 
 
    function IP-toINT64 () { 
        param ($ip) 
 
        $octets = $ip.split(".") 
        return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
    } 
 
    function INT64-toIP() { 
        param ([int64]$int) 
        return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
    } 
 
    if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)} 
    if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) } 
    if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)} 
    if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)} 
    if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))} 
 
    if ($ip) { 
        $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
        $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
    } else { 
        $startaddr = IP-toINT64 -ip $start 
        $endaddr = IP-toINT64 -ip $end 
    } 
 
    for ($i = $startaddr; $i -le $endaddr; $i++) { 
        INT64-toIP -int $i 
    }
}

function Get-Hostfile {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string]$projectpath
    )
    equals;write-host "The hostfile must have one IP address or hostname per line, no subnets" -ForegroundColor Yellow
    equals;Write-Host "If you need to get a list of IPs from a subnet I recommend nmap and awk:" -ForegroundColor Yellow
    equals;Write-Host "nmap -n -sL 10.10.10.1/23 | awk '{print `$5}'" -ForegroundColor Yellow
    equals;write-host "Enter the full path of the file containing the IP addresses: "
    equals;$hostfile = Read-Host " "
    if (Test-Path $hostfile) {
        $iplist = Get-Content $hostfile
    } else {
        minus;write-host "unable to open $hostfile"
        return
    }
    $iplist = $iplist | ? {$_} # remove blank lines from the file
    $numhosts = $iplist.count
    
    if ($numhosts -eq 0) {
        Minus;Write-Host "zero IP addresses in the selected range" -ForegroundColor Red
        return
    }
    plus;Write-Host "$numhosts ip addresses in that file" -ForegroundColor Green
    if ($numhosts -gt 255) {
        Minus;Write-Host "WARNING: $numhosts IP addresses in the selected range, this could take a while" -ForegroundColor Red
        Minus;Write-Host "You can ctrl-c to kill the script if things get out of hand" -ForegroundColor Red
    }
    $verifiedIP = Check-connection $iplist
    plus;Write-Host "$($verifiedIP.count) hosts are responding to pings"
    Start-PSHostScan -iplist $verifiedIP -projectpath $projectpath
}

Function Get-Subnet {
    <#
        .Synopsis
        Prompt the user for how they want to enter the subnets, future versions may auto-detect this
        Calling Get-IPrange to parse the subnets into a list of IP addresses
        
    #>
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string]$projectpath
    )
    plus;Write-Host "Do you want to use CIDR notation or Netmask notation?" 
    plus;Write-Host "1. CIDR Notation, i.e. 10.10.10.0/24" 
    plus;Write-Host "2. Netmask notation, i.e. 10.10.10.0 255.255.128.0" 
    plus;Write-Host "3. IP range notation, i.e. 10.10.10.5 10.10.10.8" 
    plus;Write-Host "4. Exit" -ForegroundColor Green
    equals;$answer = Read-Host "Enter your selection"
    switch ($answer){
        "1" { # CIDR notation
            equals;$iprange = Read-Host "Enter the netmask in CIDR notation" 
            if (($iprange.Split("/")).Count -ne 2) { # they didn't use CIDR notation
                minus;write-host "That doesn't look like CIDR notation" -ForegroundColor Red
                return
            }
            $iplist = Get-IPrange -ip $iprange.Split("/")[0] -cidr $iprange.Split("/")[1]
        }

        "2" {# Netmask notation
            equals;$network = Read-Host "Enter the network"
            equals;$netmask = Read-Host "Enter the netmask"
            if($network -notmatch [IPAddress]$network){
                minus;Write-Host "$network isn't a valid IP address"
                return
            }
            if($netmask -notmatch [IPAddress]$netmask){
                minus;Write-Host "$netmask isn't a valid netmask"
                return
            }
            $iplist = Get-IPrange -ip $network -mask $netmask
        }

        "3" {# IP range notation
            equals;$startip = Read-Host "Enter the first IP"
            equals;$stopip = Read-Host "Enter the last IP"
            if($startip -notmatch [IPAddress]$startip){
                minus;Write-Host "$startip isn't a valid IP address"
                return
            }
            if($stopip -notmatch [IPAddress]$stopip){
                minus;Write-Host "$stopip isn't a valid netmask"
                return
            }
            $iplist = Get-IPrange -start $startip -end $stopip
        }

        "4" {# exit
            minus;Write-Host "Returning to Scan Module" -ForegroundColor yellow
            return
        }
        default { # User is not following directions
            minus;Write-Host "You didn't make a valid choice" -ForegroundColor Yellow
            return
        }
    }
    $numhosts = $iplist.count
    if ($numhosts -eq 0) {
        Minus;Write-Host "zero IP addresses in the selected range" -ForegroundColor Red
    }
    if ($numhosts -gt 255) {
        Minus;Write-Host "WARNING: $numhosts IP addresses in the selected range, this could take a while" -ForegroundColor Red
        Minus;Write-Host "You can ctrl-c to kill the script if things get out of hand" -ForegroundColor Red
    }
    $verifiedIP = Check-connection $iplist
    plus;Write-Host "$($verifiedIP.count) hosts are responding to pings"
    Start-PSHostScan -iplist $verifiedIP -projectpath $projectpath
}

Function Check-connection {
    Param(
        [Parameter(Mandatory=$true)]
        $iplist
    )
    plus;Write-Host "Pinging the hosts to see if they are up." -ForegroundColor Green
    foreach ($ip in $iplist){
        $a = Test-Connection -ComputerName $ip -ErrorAction SilentlyContinue -Count 2 -AsJob
    }

    while (Get-Job -State Running){
        sleep 3
        plus;Write-Host "waiting for ping results to return..." -ForegroundColor Green
    }
   
    plus;Write-Host "ping responses returned." -ForegroundColor Green
    $PingStatus = Get-Job -State Completed | Receive-Job
    $verified = @()
    foreach ($ping in $PingStatus){
        if ($ping.StatusCode -eq 0){
            # plus; write-host "$($ping.address) is up"
            $verified += "$($ping.Address.ToString())"
        }
    }
    $verified =  $verified | select -Unique
    return $verified
}

Function Test-Credential { 
    [OutputType([Bool])] 
     
    Param ( 
        [Parameter( 
            Mandatory = $true, 
            ValueFromPipeLine = $true, 
            ValueFromPipelineByPropertyName = $true 
        )] 
        [Alias('PSCredential')] 
        [ValidateNotNull()] 
        [System.Management.Automation.PSCredential] 
        [System.Management.Automation.Credential()]$Credential, 
 
        [Parameter()] 
        [String]$Domain = $Credential.GetNetworkCredential().Domain 
    ) 
    Begin { 
        [System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement") | Out-Null 
        $principalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext( 
            [System.DirectoryServices.AccountManagement.ContextType]::Domain, $Domain 
        ) 
    } 
 
    Process { 
        foreach ($item in $Credential) { 
            $networkCredential = $Credential.GetNetworkCredential()         
            Write-Output -InputObject $( 
                $principalContext.ValidateCredentials( 
                    $networkCredential.UserName, $networkCredential.Password 
                ) 
            ) 
        } 
    } 
    End { $principalContext.Dispose() 
    } 
}

Function Scan-IPAddress{
    <#
        .Synopsis
        Calls start-pshostscan on a single IP address or hostname
    #>
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string]$projectpath
    )
    equals; $computername = Read-Host "Enter the hostname or IP to scan"
    Start-PSHostScan -iplist $computername -projectpath $projectpath
        return $false
}

Function Start-PSHostScan {
    Param(
        [Parameter(Mandatory=$true)]
        $iplist,
        $projectpath
    )
    equals; Write-Host "Going to prompt you for credentials. This is where you enter your IA creds" -ForegroundColor Yellow
    equals; Write-Host "The information will be stored in a secure string in memory, not saved to disk anywhere" -ForegroundColor Yellow
    equals; Write-Host "If you are using a smart card you can select that option in the dropdown menu that pops up" -ForegroundColor Yellow
    equals; $wait = Read-Host "Press any key to continue"
    $creds = Get-Credential -Credential "$env:USERDOMAIN\$env:USERNAME"
    # verify the creds before we continue
    if (Test-Credential -Credential $creds) {
        plus;Write-Host "Verified Credentials for $($creds.UserName)"
        plus;Write-Host "Going to try to open a PowerShell Session with $($iplist.count) IP addresses"
        Invoke-Scan -projectpath $projectpath -iplist $iplist -creds $creds
    } else {
    minus;Write-Host "Those credentials are not valid. Find out what went wrong and try again." -ForegroundColor Red
    minus;Write-Host "Try to not lock yourself out." -ForegroundColor Red
    }

}

function Invoke-Scan {
    <#
        .Synopsis
        Function for multithreading the scanning of a range of hosts
        requires the projectpath argument to know where to create the output folders
        requires the iplist param as an array of IP addresses or hostnames
    #>

    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string]$projectpath,
        [Parameter(Mandatory=$True,Position=2)]
        [array]$iplist,
        [parameter(Mandatory=$True,Position=3)]
        [system.Object]$creds,
        $maxthreads = 10 # number of hosts to open a session with at one time. can be adjusted to speed up or slow down scans        
    )
    Get-Job | Remove-Job 
    Get-PSSession | Remove-PSSession
    $session = New-PSSession -ComputerName $iplist -Credential $creds -ErrorAction SilentlyContinue -ErrorVariable $failedsessions -ThrottleLimit $maxthreads
    
    plus;Write-Host "Successfully Opened $($session.count) PowerShell Sessions"
    
    $sessionlist = Get-PSSession | select ComputerName
    $sessionlist = $sessionlist | % {$_.ComputerName}
    $failedSessions = Compare-Object -ReferenceObject $iplist -DifferenceObject $sessionlist
    foreach ($failedSess in $failedSessions.InputObject){
        minus;Write-Host "Failed to create a PowerShell session on $failedSess" -ForegroundColor Yellow
    }
    Out-File -FilePath $projectpath\FAILED_SESSIONS.txt -InputObject $failedSessions.InputObject

    foreach ($s in $session){
        plus;Write-Host "Opened a session with $($s.ComputerName)"
        Invoke-Command -Session $s -FilePath .\PSSurvey.ps1 -AsJob | Out-Null # start the script as a job
    }
    $totaljobs = $session.count

    while ($True){
        Write-Progress -Activity "Waiting on Scan results" -Status "Events Processed" -PercentComplete ((1 - (((get-Job -State Running).count) / $totaljobs)) * 100) -CurrentOperation "Waiting on $((get-Job -State Running).count) Sessions to return"
        if ($joblist = Get-Job -state Completed -HasMoreData $True) {
            foreach ($job in $joblist){
                $scanresults = Receive-Job $job
                $hostname = $job.Location
                plus; Write-Host "Collecting data from $hostname and writing to $projectpath\$hostname.systemscan.txt"
                Out-File -FilePath "$projectpath\$hostname.systemscan.txt" -InputObject $scanresults
                $job | Remove-Job
            }
        }
        if ((-not (Get-Job -State Running)) -and (-not(Get-Job -State Completed))) {
            plus; Write-Host "All scans completed" -ForegroundColor Green
            Get-Job | Remove-Job
            Get-PSSession | Remove-PSSession
            $alerts = Select-String -Path $projectpath\* -Pattern "!!! ALERT !!!"
            if ($alerts){
                Minus;Write-Host "Critical Alerts found, investigate these" -ForegroundColor Red
                Equals;
                $alerts | % {Write-Host $_ -ForegroundColor Red}
                Equals; Write-Host "Alerts saved in $projectpath\Alerts.txt" -ForegroundColor Yellow
                Out-File -FilePath $projectpath\ALERTS.txt -InputObject $alerts
            }
            return
        }
        sleep 5
    }   
}

Invoke-SystemScanner
