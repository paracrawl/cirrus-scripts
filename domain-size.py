#!/usr/bin/env python3
import sys
import gzip
import re
import os
from io import TextIOWrapper
from collections import Counter
from multiprocessing.pool import Pool


def domain(url):
  match = re.match(r'^(https?:)?(//)?(?P<domain>[^/]+)', url)
  return match.group('domain') if match else url


def batch_size_per_domain(batch):
	counter = Counter()

	with gzip.open(os.path.join(batch, 'url.gz')) as fh_url, \
	gzip.open(os.path.join(batch, 'sentences.gz')) as fh_text:
		for url, text in zip(fh_url, fh_text):
			counter[domain(url.decode())] += len(text)

	return counter


def shard_batches(shard):
	for entry in os.scandir(shard):
		if entry.name.isdigit():
			yield entry.path


def shard_size_per_domain(shard, pool):
	# Since 3.8 you can do this with sum(..., start=Counter()) I think?
	totals = Counter()
	for counter in pool.imap_unordered(batch_size_per_domain, shard_batches(shard)):
		totals += counter
	return totals

pool = Pool(8)

for shard in sys.argv[1:]:
	totals = shard_size_per_domain(shard, pool)
	# for domain, size in totals.most_common():
	# 	print("{}\t{}".format(domain, size))

	with gzip.open(os.path.join(shard, 'sizes.gz'), 'wb') as fh, \
	TextIOWrapper(fh) as fout:
		for domain, size in totals.most_common():
			print("{}\t{}".format(domain, size), file=fout)
