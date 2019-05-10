#!/bin/sh
PG_HOST="`cat ~/dev/go/src/github.com/cncf/devstats-helm-graphql/devstats-helm-graphql/secrets/PG_HOST.secret`" PG_PASS="`cat ~/dev/go/src/github.com/cncf/devstats-helm-graphql/devstats-helm-graphql/secrets/PG_PASS.secret`" ~/dev/go/src/github.com/cncf/devstats/devel/k8s_generate_actors_graphql.sh > ~/dev/alt/gitdm/src/actors_gql.txt
sed -i '/pod "devstats-actors/d' actors_gql.txt
cat actors_gql.txt | sort | uniq > out && mv out actors_gql.txt
