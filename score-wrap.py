#!/usr/bin/env python3
# Script that reads sentences scored with hardrules
# prints the 0's directly to stdout
# and passes the sentences with 1 to the subprocess bicleaner score

from subprocess import run, PIPE
import sys
import os

scores = []
lines = []
for line in sys.stdin:
    parts = line.rstrip("\n").split("\t")

    score = parts[-1]
    scores.append(parts[-1])
    if score == "1":
        # only save urls and seg columns
        lines.append('\t'.join(parts[:4]))
    elif score != "1" and score != "0":
        sys.stderr.write(f"Error: unexpected score '{score}' at line {len(scores)+1}\n")
        sys.exit(1)

# run command with the lines that have score 1
lines = '\n'.join(lines) + '\n'
output = run(sys.argv[1:], input=lines, stdout=PIPE, stderr=PIPE, env=os.environ, encoding='utf-8')

sys.stderr.write(output.stderr)
if output.returncode != 0:
    sys.exit(1)

output = output.stdout.split("\n")
p = iter(output)
# print scores replacing 1's by the subprocess score
for score in scores:
    if score == "1":
        print(next(p))
    else:
        print(score)
