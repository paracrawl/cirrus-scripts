#!/usr/bin/env python

## Split appropriately for whole-node jobs on cirrus

from sys import argv
import fileinput

nrows=432

slice=0
n=nrows
ofp=None
filebase=argv[1]
for row in fileinput.input(filebase):
    if n >= nrows:
        if ofp is not None:
            ofp.close()
        slice += 1
        ofp = open("%s.%d" % (filebase, slice), "w+")
        n = 0
    ofp.write(row)
    n += 1
