#!/bin/sh
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to set PG_PASS env variable"
  exit 1
fi
PG_HOST="`cat ~/dev/go/src/github.com/cncf/devstats-helm/devstats-helm/secrets/PG_HOST.secret`" ~/dev/go/src/github.com/cncf/devstats/devel/k8s_generate_actors_nonlf.sh > ~/dev/alt/gitdm/src/actors_nonlf.txt
sed -i '/pod "devstats-actors/d' actors_nonlf.txt
cat actors_nonlf.txt | sort | uniq > out && mv out actors_nonlf.txt
