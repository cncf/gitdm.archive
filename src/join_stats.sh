#!/bin/sh
echo "All CNCF Projects Join statistics (authors, commits, additions, removals) 90 days before and after joining CNCF"
./cncf_join_analysis.sh prometheus 2016-05-09 90 ~/dev/prometheus/
./cncf_join_analysis.sh prometheus_6m 2016-05-09 183 ~/dev/prometheus/
./cncf_join_analysis.sh prometheus_1y 2016-05-09 365 ~/dev/prometheus/
./cncf_join_analysis.sh kubernetes 2016-03-10 90 ~/dev/kubernetes_repos_links
./cncf_join_analysis.sh opentracing 2016-08-17 90 ~/dev/opentracing/
./cncf_join_analysis.sh fluentd 2016-08-03 90 ~/dev/fluentd/
./cncf_join_analysis.sh linkerd 2016-10-05 90 ~/dev/linkerd/
./cncf_join_analysis.sh grpc 2016-10-19 90 ~/dev/grpc/
./cncf_join_analysis.sh coredns 2016-08-17 90 ~/dev/coredns/
./cncf_join_analysis.sh containerd 2017-03-15 90 ~/dev/containerd/
./cncf_join_analysis.sh rkt 2017-03-15 75 ~/dev/rkt/
./cncf_join_analysis.sh cni 2017-05-03 30 ~/dev/cni/

./cncf_join_analysis.sh etcd 2016-05-09 90 ~/dev/etcd/
./cncf_join_analysis.sh etcd_6m 2016-05-09 183 ~/dev/etcd/
./cncf_join_analysis.sh etcd_1y 2016-05-09 365 ~/dev/etcd/
