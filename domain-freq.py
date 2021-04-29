#!/usr/bin/env python3
import sys
import gzip
import re
from io import TextIOWrapper
from collections import Counter, defaultdict
from multiprocessing.pool import Pool


def sum_domains(paths):
	counter = Counter()

	for path in paths:
		with gzip.open(path.rstrip(), 'r') as fh:
			for linenr, line in enumerate(TextIOWrapper(fh, encoding='utf-8'), start=1):
				match = re.match(r'^\s*(\d+)\s+(.+)$', line.rstrip())
				# Tell me I messed up
				if not match:
					print("Ignoring line '{}' in {}".format(line.rstrip(), path, linenr), file=sys.stderr)
					continue
				# Ignore the small stuff
				if int(match[1]) < 10:
					break

				counter[match[2]] += int(match[1])

	return counter


shards = defaultdict(list)

for path in sys.stdin:
	_, shard, _ = path.strip().rsplit('/', maxsplit=2)
	shards[shard].append(path)

print("{} shards".format(len(shards)), file=sys.stderr)

pool = Pool(16)

for counter in pool.imap_unordered(sum_domains, shards.values()):
	for domain, count in counter.items():
		print("{}\t{}".format(domain, count))
	
