#!/bin/sh
sudo -u postgres psql -tA gha < ~/dev/go/src/devstats/util_sql/contributing_actors.sql > actors.txt
sudo -u postgres psql -tA prometheus < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA opentracing < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA fluentd < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA linkerd < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA grpc < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA coredns < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA containerd < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA rkt < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA cni < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA envoy < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA jaeger < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA notary < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA tuf < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA rook < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA vitess < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA nats < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA opa < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA spiffe < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA spire < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA opencontainers < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql -tA cncf < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
cat actors.txt | sort | uniq > actors.tmp
tr '\n' ',' < actors.tmp > out
rm actors.tmp
mv out actors.txt
truncate -s-1 actors.txt
