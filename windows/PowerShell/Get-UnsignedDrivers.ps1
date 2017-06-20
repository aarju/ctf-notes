Function Get-UnsignedDrivers {
    ((gwmi win32_systemdriver -Filter 'Started="True"').Pathname | gi -ea ig | Get-AuthenticodeSignature | ? {$_.Status -eq "NotSigned"})
}
