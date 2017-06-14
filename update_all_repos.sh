#!/bin/sh
cd ~/dev/go/src/k8s.io/
for f in `find . -type d -depth 1`
do
  echo "$f"
  cd "$f" && git reset --hard && git checkout master && git pull
  cd ~/dev/go/src/k8s.io/
done
