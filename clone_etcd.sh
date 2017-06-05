#!/bin/sh
mkdir ~/dev/etcd/ 2>/dev/null
cd ~/dev/etcd || exit 1
git clone https://github.com/coreos/etcd.git || exit 1
echo "All etcd repos cloned"
