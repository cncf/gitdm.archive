#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to set PG_PASS=..."
  exit 1
fi
PG_DB=cii GHA2DB_SKIPTIME=1 GHA2DB_LOCAL=1 GHA2DB_CSVOUT=top_repos_committers.csv runq sql/top_repos_committers.sql {{exclude_bots}} "`cat ~/dev/go/src/github.com/cncf/devstats/util_sql/exclude_bots.sql`"
