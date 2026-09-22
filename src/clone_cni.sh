#!/bin/sh
mkdir ~/dev/cni/ 2>/dev/null
# This list is from `cncf/velocity`:`BigQuery/query_cncf_repos.sql`
cd ~/dev/cni || exit 1
git clone https://github.com/containernetworking/cni.git || exit 1
git clone https://github.com/containernetworking/plugins.git || exit 1
echo "All CNI repos cloned"
