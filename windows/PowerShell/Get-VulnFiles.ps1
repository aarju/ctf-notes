# Find all files and folders on a drive that have FullControl permissions set for the Users group
# Search the drive for files with the 'F' Flag set on the 'Users' or 'anyone' group. 
# Return a list of the files and directories. Maybe make a -directory option.

function Get-vulnFiles {
    # find all files on a system with the 'FullAccess' flag set on the Users group.
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$False)] [switch]$Directory = $False, # -Directory will only return dirs
        [Parameter(Mandatory=$True)] [string]$Path
    )
    
    $vulnfiles = @() # array for storing the successfull results
    
    # if the directory flag is set, add the -directory option to the search.    
    if ($Directory){
        $files = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue -Recurse -Directory
    }
    else {
        $files = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue -Recurse
    }
    
    foreach ($file in $files){
        $i++; Write-Progress -activity "Scanning folders" -status "Percent scanned: " -percentComplete (($i / $files.length) * 100)
        foreach ($acl in (Get-Acl -ErrorAction SilentlyContinue $file.fullname).access) {
            if ($acl.IdentityReference -match "Users" -and $acl.FileSystemRights -match "FullControl"){
                $vulnfiles += $file.FullName
            }
            else {
            }
        }
    }
    Write-Host $vulnfiles
    return $vulnfiles
}

