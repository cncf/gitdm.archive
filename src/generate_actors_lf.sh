#!/bin/sh
PG_HOST="`cat ~/dev/go/src/github.com/cncf/devstats-helm-lf/devstats-helm/secrets/PG_HOST.secret`" PG_PASS="`cat ~/dev/go/src/github.com/cncf/devstats-helm-lf/devstats-helm/secrets/PG_PASS.secret`" ~/dev/go/src/github.com/cncf/devstats/devel/k8s_generate_actors_lf.sh > ~/dev/alt/gitdm/src/actors_lf.txt
sed -i '/pod "devstats-actors/d' actors_lf.txt
cat actors_lf.txt | sort | uniq > out && mv out actors_lf.txt
./scrub.rb actors_lf.txt
