#!/bin/bash
cp actors_lf.txt actors.txt
./scrub.rb actors.txt
sudo -u postgres psql -tA gha < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA prometheus < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA opentracing < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA fluentd < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA linkerd < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA grpc < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA coredns < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA containerd < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA rkt < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA cni < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA envoy < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA jaeger < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA notary < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA tuf < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA rook < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA vitess < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA nats < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA opa < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA spiffe < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA spire < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA contrib < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA cloudevents < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA telepresence < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA helm < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA harbor < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA openmetrics < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA etcd < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA tikv < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA cortex < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA buildpacks < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA falco < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA dragonfly < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA virtualkubelet < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA kubeedge < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA brigade < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA crio < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA networkservicemesh < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA openebs < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA cncf < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA allprj < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA opencontainers < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA istio < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA knative < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA linux < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA zephyr < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
# Actors from CDF - assume they're CNCF actors
psql -h devstats.cd.foundation -U postgres -tA spinnaker < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
psql -h devstats.cd.foundation -U postgres -tA tekton < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
psql -h devstats.cd.foundation -U postgres -tA jenkins < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
psql -h devstats.cd.foundation -U postgres -tA jenkinsx < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
psql -h devstats.cd.foundation -U postgres -tA allcdf < ~/dev/go/src/github.com/cncf/devstats/util_sql/actors.sql >> actors.txt
# cp actors.txt all_actors.txt
cat actors.txt | sort | uniq > actors.tmp
tr '\n' ',' < actors.tmp > out
rm actors.tmp
mv out actors.txt
truncate -s-1 actors.txt
