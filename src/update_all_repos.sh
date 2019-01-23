#!/bin/sh
cd ~/dev/go/src/k8s.io/
for f in `find . -type d -maxdepth 1 -iname "[a-zA-Z0-9]*"`
do
  echo "$f"
  cd "$f" && git reset --hard && git checkout master && git pull
  cd ~/dev/go/src/k8s.io/
done
