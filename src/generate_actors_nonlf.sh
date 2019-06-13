#!/bin/sh
PG_HOST="`cat ~/dev/go/src/github.com/cncf/devstats-helm/devstats-helm/secrets/PG_HOST.secret`" PG_PASS="`cat ~/dev/go/src/github.com/cncf/devstats-helm/devstats-helm/secrets/PG_PASS.secret`" ~/dev/go/src/github.com/cncf/devstats/devel/k8s_generate_actors_nonlf.sh > ~/dev/alt/gitdm/src/actors_nonlf.txt
sed -i '/pod "devstats-actors/d' actors_nonlf.txt
cat actors_nonlf.txt | sort | uniq > out && mv out actors_nonlf.txt
