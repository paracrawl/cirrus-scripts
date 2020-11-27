#!/usr/bin/env python3
import sys
import unicodedata

def remove_control_characters(text):
  return "".join(ch for ch in text if unicodedata.category(ch)[0]!="C")

for n, line in enumerate(sys.stdin.buffer, start=1):
  try:
    fields = line.rstrip(b"\n").decode().split("\t")
    line = "\t".join(remove_control_characters(field) for field in fields)
    print(line)
  except UnicodeError:
   	print("Line {} contains invalid unicode".format(n), file=sys.stderr)
