BEGIN {
	GZIP_CMD="pigz -c > out%d.gz";
	
	should_split=0;
	num=0;
	gzip=sprintf(GZIP_CMD, num)
}

NR % 100000000 == 0 {
	print "Should split" > "/dev/stderr";
	should_split=1;
	checksum=$7
}

should_split == 1 && $7 != checksum {
	print sprintf("Splitting on line %d (from %s to %s)", NR, checksum, $7) > "/dev/stderr";
	num++;
	close(gzip);
	gzip=sprintf(GZIP_CMD, num);
	should_split=0;
}

{
	print |& gzip
}

END {
	close(gzip)
}
