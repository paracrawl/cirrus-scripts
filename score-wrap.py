#!/usr/bin/env python3
# Script that reads sentences scored with hardrules
# prints the 0's directly to stdout
# and passes the sentences with 1 to the subprocess bicleaner score
import sys
import subprocess
from threading import Thread
from queue import Queue
from itertools import chain


def fast_forward(stdin, stdout):
    """While the input lines are marked with a score of 0, just write the 0
    directly to the stdout. Only once we read a line that's not with a score of
    0 we stop and return the line. If all input lines were score of 0, return
    None."""
    for line in stdin:
        parts = line.rstrip("\n").split("\t")

        if parts[-1] == "0":
            stdout.write("0\n")
        else:
            return line

    return None


def stdin_to_child(out_queue, stdin, child_in):
    """Reads sys.stdin and queues all lines for writing output. Lines that need
    to be scored are also fed to the child process. Ends with putting a None on
    the queue to indicate the feeding is done."""
    try:
        for line in stdin:
            parts = line.rstrip("\n").split("\t")
            
            if parts[-1] == "0":
                pass
            elif parts[-1] == "1":
                child_in.write("\t".join(parts[:4]) + "\n")
            else:
                raise Exception(f"Unknown input in score column: '{parts[-1]}'. Only expecting '0' or '1'.")
            
            out_queue.put(parts[-1])
        out_queue.put(None)
    except Exception as e:
        out_queue.put(e)
    finally:
        child_in.close()


def child_to_stdout(out_queue, child_out, stdout):
    """Reads the queue, and when the value on the queue indicates that we should
    ask the child process for the real value, it will read the value from the
    child. When it reads a None it will stop."""
    while True:
        line = out_queue.get()

        # None is poison
        if line is None:
            break

        if isinstance(line, Exception):
            raise line

        # 0 skips child, just writes 0
        elif line == "0":
            stdout.write("0\n")

        # 1: line was passed to child, query child for value
        elif line == "1":
            stdout.write(child_out.readline())

        # Anything else should not happen
        else:
            raise Exception(f"Unknown value in queue: '{line}'")


def usage(prog):
    print(f"Usage: {prog} command [arg...]", file=sys.stderr)
    return 1


def main(argv):
    if len(argv) <= 1:
        return usage(argv[0])

    # Fast-forward while all lines are marked with a score of 0. If we have hit
    # a file that only has these kind of lines, we can skip starting the child
    # process without feeding it anything.
    next_line = fast_forward(sys.stdin, sys.stdout)
    if next_line is None:
        return 0

    child = subprocess.Popen(argv[1:], stdin=subprocess.PIPE, stdout=subprocess.PIPE, encoding='utf-8')

    # queue contains 0 if a 0 needs to be written, 1 if a score from the child
    # needs to be read & written, or None if we're at the end of the input. Then
    # the child's stdin is closed.
    queue = Queue()

    # feeder feeds stdin to queue, and lines that need to be scored to child.
    # Use chain() to stick next_line back onto the stdin feed.
    feeder = Thread(target=stdin_to_child, args=[queue, chain([next_line], sys.stdin), child.stdin])
    feeder.start()

    # child_to_stdout reads scores from queue, and if a score is 1 also the
    # actual score from child. Will stop when it encounters None in queue.
    child_to_stdout(queue, child.stdout, sys.stdout)

    feeder.join()

    # Assuming we've processed all output, child should be finished producing
    # output by now.
    child.wait()

    return child.returncode


sys.exit(main(sys.argv))
