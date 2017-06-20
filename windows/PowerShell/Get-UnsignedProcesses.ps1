Function Get-UnsignedProcesses {
  ps | gi -ea ig | Get-AuthenticodeSignature | ? { $_.SignerCertificate.Subject -eq $null}
}
