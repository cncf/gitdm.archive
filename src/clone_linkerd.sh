#!/bin/sh
mkdir ~/dev/linkerd/ 2>/dev/null
# This list is from `cncf/velocity`:`BigQuery/query_cncf_repos.sql`
cd ~/dev/linkerd || exit 1
git clone https://github.com/linkerd/linkerd.git || exit 1
git clone https://github.com/linkerd/linkerd-examples.git || exit 1
git clone https://github.com/linkerd/linkerd-tcp.git || exit 1
git clone https://github.com/linkerd/linkerd-viz.git || exit 1
git clone https://github.com/linkerd/linkerd-zipkin.git || exit 1
git clone https://github.com/linkerd/namerctl.git || exit 1
git clone https://github.com/linkerd/rustup-nightly-docker.git || exit 1
git clone https://github.com/linkerd/tacho.git || exit 1
echo "All Linkerd repos cloned"
