#!/bin/sh
sudo -u postgres psql gha < ~/dev/go/src/devstats/util_sql/contributing_actors.sql > actors.txt
sudo -u postgres psql prometheus < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql opentracing < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql fluentd < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql linkerd < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql grpc < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql coredns < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
sudo -u postgres psql containerd < ~/dev/go/src/devstats/util_sql/contributing_actors.sql >> actors.txt
