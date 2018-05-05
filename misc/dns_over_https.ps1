function Resolve-DnsOverHTTPS ($domain) {
      $request = "https://dns.google.com/resolve?name=$domain&edns_client_subnet=0.0.0.0/0&type=1"
      $response = Invoke-WebRequest -Uri $request
      ((ConvertFrom-Json $response.Content).Answer)[0].data
}

# Shortened version for use in a stager
function sdns ($d) {
    ((ConvertFrom-Json (iwr "https://dns.google.com/resolve?name=$d").Content).Answer)[0].data
}