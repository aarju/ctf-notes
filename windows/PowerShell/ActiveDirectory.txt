Find a server by the IP 
Get-ADComputer -property * -filter { ipv4address -eq '136.221.74.82' }


Find all Servers and export to a csv
Get-ADComputer -Filter {OperatingSystem -Like "Windows Server*"} -Property * | select Name,OperatingSystem,OperatingSystemServicePack,IPV4Address,Description | Export-Csv -Path serverlist.csv

Find all Workstations and export to a csv
Get-ADComputer -Filter {OperatingSystem -notlike "*Server*"} -Property * | select Name,OperatingSystem,OperatingSystemServicePack,IPV4Address,Description | Export-Csv -Path workstationlist.csv

Find all writable SYSTEM directories on a host
$list = @(Get-ChildItem -Recurse -System -Directory -ErrorAction SilentlyContinue); foreach ($dir in $list) { $dir.FullName }

Find all Domain Controllers
(Get-ADDomainController -Filter "*") | Format-Table Name,IPv4Address

Get a list of users that can log in without a CAC
function Get-NoCACUsers {
    <#
        .SYNOPSIS
        Runs an LDAP query looking for any user that is able to log in without a CAC

        .PARAMETER DomainController
        The IP address of the Domain Controller to run the query against. If not provided it will run the query against the default domaincontroller

    #>
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [String]$DomainController = (Get-ADDomainController).IPv4Address
    )

    $DCLDAPPort = (Get-ADDomainController -Server $DomainController).LdapPort
    $ldapstring = "LDAP://" +$DomainController + ":" + $DCLDAPPort
    $root = [ADSI]$ldapstring
    $search = New-Object System.DirectoryServices.DirectorySearcher($root,"(&(objectClass=user)(objectCategory=person)(!userAccountControl:1.2.840.113556.1.4.803:=2)(!userAccountControl:1.2.840.113556.1.4.803:=262144))")
    $noCacUsers = $search.FindAll()
    foreach($result in $noCacUsers){
        $result.Properties.samaccountname
    }
}


