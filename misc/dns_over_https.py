
'''
Purpose: use Google DNS over HTTPS to resolve a hostname

Arguments:
    domain       Return the IPv4 address of the requested domain
   
https://dns.google.com/resolve?name=example

'''

import argparse
import json
import urllib.request
import string
import random

# read in the domain name
parser = argparse.ArgumentParser()
parser.add_argument("domain")
domain_input = parser.parse_args().domain

def https_dns_query(domain):
    if len(domain) < 500: # pad all requests up to at least 500 characters
        sizeof_padding = 500 - len(domain)
        i = 1
        padding = ""
        while i < sizeof_padding:
            padding += random.choice(string.ascii_letters)
            i = i+1
    fullurl = "https://dns.google.com/resolve?name=" + domain + \
        "&edns_client_subnet=0.0.0.0/0&type=1&random_padding=" + padding

    raw_response = urllib.request.urlopen(fullurl)
    charset = raw_response.info().get_content_charset()
    response = raw_response.read().decode(charset)

    answers = json.loads(response)['Answer']
    for answer in answers:
        names = []
        if answer['type'] == 1:
            names.append(answer['data'])
    return names


print(https_dns_query(domain_input))

# exit with help if no arguments were given

# execute the API request with the domain name

# return the 
