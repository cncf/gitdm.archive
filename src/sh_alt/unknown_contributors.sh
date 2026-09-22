#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to set PG_PASS=..."
  exit 1
fi
PG_DB=cii GHA2DB_LOCAL=1 GHA2DB_CSVOUT=unknown_contributors.csv ./runq sql/unknown_contributors.sql {{exclude_bots}} "`cat sql/exclude_bots.sql`"
