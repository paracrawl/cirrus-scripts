#!/usr/bin/env python3
import sys
import re
import base64

for n, line in enumerate(sys.stdin.buffer, 1):
	document = base64.decodebytes(line).decode('utf-8')
	length = len(document)
	if length < 2000:
		continue
	wordcount = document.count(' ') + document.count('\n') + 1
	alphanumcnt = len(re.sub(r'[^a-zA-Z0-9-_,/\.]', '', document))
	print("{:d}\t{:0.3f}\t{}\t{}".format(n, alphanumcnt / length, length, wordcount, alphanumcnt))
