Function Get-MD5 {
    Param(
    [Parameter(Mandatory=$true)]
    $file
    )
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $filehash = ([System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes("$file"))))
    return $filehash.replace('-','')
}
