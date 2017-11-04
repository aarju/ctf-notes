'''
Identify how many word-hash pairs actually match.

For example, given the following list:

max 9baf3a40312f39849f46dad1040f2f039f1cffa1238c41e9db675315cfad39b6 => True
min 1f6fa6f69d185e6086d04e7330361bf9001a3b8d0ce511171055dc34eb90c1c1 => False
ord 55df18d062878fb6d3f4a6d1928fd19c1b49d5f8b90fbfcc76d5e1b1b2b75ef8 => True
Thus two strings actually match. For your answer, you would enter 2.
'''

import hashlib

f = open('wordhash.txt','r')
lines = f.readlines()
f.close()
count = 0
for line in lines:
    word = line.split()[0]
    hashstring = line.split()[1]
    if hashstring == str(hashlib.sha256(word).hexdigest()):
        count += 1

print count





