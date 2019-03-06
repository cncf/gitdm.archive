#!/bin/bash
sudo -u postgres psql -tA gha < ~/dev/go/src/devstats/util_sql/actors.sql > actors.txt
sudo -u postgres psql -tA prometheus < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA opentracing < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA fluentd < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA linkerd < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA grpc < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA coredns < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA containerd < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA rkt < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA cni < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA envoy < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA jaeger < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA notary < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA tuf < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA rook < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA vitess < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA nats < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA opa < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA spiffe < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA spire < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA contrib < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA cloudevents < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA telepresence < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA helm < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA harbor < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA openmetrics < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA etcd < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA tikv < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA cortex < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA buildpacks < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA falco < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA dragonfly < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA virtualkubelet < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA cncf < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA allprj < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA opencontainers < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA istio < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres PGPASSWORD="${PG_PASS}" psql -h devstats.cd.foundation -tA spinnaker < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA knative < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres PGPASSWORD="${PG_PASS}" psql -h devstats.cd.foundation -tA tekton < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres PGPASSWORD="${PG_PASS}" psql -h devstats.cd.foundation -tA jenkins < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres PGPASSWORD="${PG_PASS}" psql -h devstats.cd.foundation -tA jenkinsx < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA linux < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
sudo -u postgres psql -tA zephyr < ~/dev/go/src/devstats/util_sql/actors.sql >> actors.txt
cat actors.txt | sort | uniq > actors.tmp
tr '\n' ',' < actors.tmp > out
rm actors.tmp
mv out actors.txt
truncate -s-1 actors.txt
