#!/bin/sh
mkdir ~/dev/containerd/ 2>/dev/null
# This list is from `cncf/velocity`:`BigQuery/query_cncf_repos.sql`
cd ~/dev/containerd || exit 1
git clone https://github.com/containerd/btrfs.git || exit 1
git clone https://github.com/containerd/cgroups.git || exit 1
git clone https://github.com/containerd/console.git || exit 1
git clone https://github.com/containerd/containerd.git || exit 1
mv containerd/ containerd.containderd
git clone https://github.com/containerd/continuity.git || exit 1
git clone https://github.com/containerd/fifo.git || exit 1
git clone https://github.com/containerd/go-runc.git || exit 1
git clone https://github.com/docker/containerd.git || exit 1
echo "All containerd repos cloned"
