#!/bin/sh
mkdir ~/dev/coredns/ 2>/dev/null
# This list is from `cncf/velocity`:`BigQuery/query_cncf_repos.sql`
cd ~/dev/coredns || exit 1
git clone https://github.com/coredns/blog.coredns.io.git || exit 1
git clone https://github.com/coredns/coredns.git || exit 1
git clone https://github.com/coredns/coredns.io.git || exit 1
git clone https://github.com/coredns/deployment.git || exit 1
git clone https://github.com/coredns/perf-tests.git || exit 1
git clone https://github.com/coredns/presentations.git || exit 1
echo "All CoreDNS repos cloned"
