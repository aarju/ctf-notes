
'''
Purpose: use Google DNS over HTTPS to resolve a hostname

Arguments:
    -d domain       Return the IPv4 address of the requested domain
    -f filename     Read in a list of domain names from a filename, return a 
                    list containing touples with the domain name and IPV4 address

Future Feature Make all DNS requests a static size by using the Random_padding function within the API.

https://dns.google.com/resolve?name=example

'''

import argparse
import urllib.request
import json

# read in the arguments
parser = argparse.ArgumentParser()
parser.add_argument("domain")
# parser.add_argument('-d','--d','--domain',type=str, help='domain name to query')
domain = parser.parse_args().domain
if len(domain) < 1500:
    padding = "A" * (1500 - len(domain))
fullurl = "https://dns.google.com/resolve?name=" + domain + "&type=1&random_padding=" + padding

rawResp = urllib.request.urlopen(fullurl)
charset = rawResp.info().get_content_charset()
response = rawResp.read().decode(charset)

answer = json.loads(response)['Answer']
try:
    for a in answer:
        if a['type'] == 1:
            print(a['data'])
except:
    pass


# exit with help if no arguments were given

# execute the API request with the domain name

# return the 

