#!/usr/bin/env python3
# Script that reads sentences scored with hardrules
# prints the 0's directly to stdout
# and passes the sentences with 1 to the subprocess bicleaner score

from subprocess import check_output
import sys
import os

scores = []
lines = []
for line in sys.stdin:
    parts = line.rstrip("\n").split("\t")

    score = parts[-1]
    scores.append(score)
    if score == "1":
        # only save urls and seg columns
        lines.append('\t'.join(parts[:4]))
    elif score != "1" and score != "0":
        sys.stderr.write(f"Error: unexpected score '{score}' at line {len(scores)+1}\n")
        sys.exit(1)

if len(lines) > 0:
    # run command with the lines that have score 1
    output = check_output(sys.argv[1:], input='\n'.join(lines) + '\n', encoding='utf-8')
else:
    output = ''

del lines

p = iter(output.split("\n"))
# print scores replacing 1's by the subprocess score
for score in scores:
    if score == "1":
        print(next(p))
    else:
        print(score)

# Check there's no superfluous output from command
end = next(p, '')
if end != '':
    sys.stderr.write(f"Error: wrapped process produced more output than input: '{end}'\n")
    sys.exit(1)
