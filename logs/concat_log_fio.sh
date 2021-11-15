#!/bin/bash

echo -n "Name;";cat headers.csv

for d in $(find . -mindepth 1 -type d); do
	rep="$(basename $d)"
	(
		cd $d
		for l in *.log; do
			echo -n "$rep;"
			grep '%;' $l
		done
	)
done