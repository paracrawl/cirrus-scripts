#!/bin/bash
find . -type f -name '*.gz~' | while read file; do
	mv $file ${file%~*}
done
