#!/bin/sh
mkdir ~/dev/rkt/ 2>/dev/null
# This list is from `cncf/velocity`:`BigQuery/query_cncf_repos.sql`
cd ~/dev/rkt || exit 1
git clone https://github.com/coreos/rkt.git || exit 1
mv rkt coreos.rkt
git clone https://github.com/rkt/rkt.git || exit 1
git clone https://github.com/rkt/stage1-xen.git || exit 1
echo "All rkt repos cloned"
