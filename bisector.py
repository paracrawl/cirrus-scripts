#!/usr/bin/env python3
import sys
import subprocess
from threading import Thread
from queue import Queue, Empty
from io import TextIOWrapper
from itertools import islice
from math import ceil


def prefix(prefix, lines):
	return "\n".join(prefix + line for line in lines.split("\n"))


class Reader(Thread):
	def __init__(self, file, queue):
		super().__init__()
		self.file = file
		self.queue = queue

	def run(self):
		while True:
			line = self.file.readline()
			if not line:
				break
			self.queue.put(line.rstrip(b"\n"))


class CrashingChild(Exception):
	pass


class UnexpectedOutput(Exception):
	def __init__(self, lines, expected):
		super().__init__("Expected {} line{}, got {}".format(expected, "s" if expected != 1 else "", len(lines)))
		self.lines = lines


class TroublesomeInput(Exception):
	def __init__(self, lines):
		super().__init__("Troublesome input on line {start} to {end}".format(start=lines[0][0], end=lines[-1][0]))
		self.lines = lines


class Child:
	def __init__(self, argv):
		self.argv = argv
		self.queue = Queue()
		self.alive = False

	def __enter__(self):
		self.start()
		return self

	def __exit__(self, exc_type, exc_value, traceback):
		if exc_type is not None:
			self.kill()
		else:
			self.close()

	def start(self):
		self.proc = subprocess.Popen(self.argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
		self.reader = Reader(self.proc.stdout, self.queue)
		self.reader.start()
		self.alive = True

	def kill(self):
		if not self.alive:
			return
		self.alive = False
		self.proc.stdin.close()
		self.proc.kill()
		# Don't wait.

	def close(self):
		if not self.alive:
			return
		self.alive = False
		
		# Indicate we're done with the child
		self.proc.stdin.close()

		# Wait for process to finish
		if self.proc.wait() != 0:
			raise CrashingChild()
		
		# Wait for reading to finish
		self.reader.join()

	def readlines(self):
		output = []
		while not self.queue.empty():
			output.append(self.queue.get())
		return output


def process_chunk(argv, lines):
	with Child(argv) as child:
		for line in lines:
			child.proc.stdin.write(line + b"\n")
		child.close()
		output = child.readlines()
	
	if len(output) != len(lines):
		raise UnexpectedOutput(output, len(lines))

	return output


def try_chunk(argv, lines, target_size=1):
	try:
		output = process_chunk(argv, list(line for _, line in lines))
	except UnexpectedOutput as e:
		print("Trouble between lines {} to {}: {}".format(lines[0][0], lines[-1][0], e), file=sys.stderr)
		if len(lines) <= target_size:
			raise TroublesomeInput(lines=lines) from e
		else:
			output = []
			for n, chunk in enumerate(grouper(lines, int(ceil(len(lines) / 2)))):
				output += try_chunk(argv, chunk, target_size=target_size)

			print("While processing the chunk {} to {} in smaller chunks instead, no errors occurred".format(lines[0][0], lines[-1][0]), file=sys.stderr)
	
	return output


def grouper(iterable, n):
	iterator = iter(iterable)
	try:
		while True:
			chunk = []
			for i in range(n):
				chunk.append(next(iterator))
			yield chunk
	except StopIteration:
		if len(chunk):
			yield chunk


def main(argv):
	argv = argv[1:] # Ditch program name
	target_size = 1

	# optional extract target size argument
	if len(argv) > 0 and argv[0].isnumeric():
		target_size = int(argv[0])
		argv = argv[1:]
	
	if len(argv) == 0:
		raise ValueError('Missing child command')

	for chunk in grouper(enumerate(sys.stdin.buffer, start=1), 1024):
		try:
			for line in try_chunk(argv, [(line_no, line.rstrip(b"\n")) for line_no, line in chunk], target_size=target_size):
				sys.stdout.buffer.write(line + b"\n")
		except TroublesomeInput as e:
			sys.stderr.write("{error!s}:\n{input}\nOutput: ({len} line{plural})\n{output}\n".format(
				error=e,
				len=len(e.__cause__.lines),
				plural="s" if len(e.__cause__.lines) != 1 else "",
				input=prefix("> ", b"\n".join(line[1] for line in e.lines).decode()),
				output=prefix("> ", b"\n".join(e.__cause__.lines).decode())))
			return 1

	return 0


if __name__ == '__main__':
	sys.exit(main(sys.argv))
