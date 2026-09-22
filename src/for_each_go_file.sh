#!/bin/bash
for f in `find ./cmd -maxdepth 3 -type f -iname "*.go" -not -path "./vendor/*"`
do
	$1 "$f" || exit 1
done
exit 0
