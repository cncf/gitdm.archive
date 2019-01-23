#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$1" ] )
then
  echo "$0: you need to set password via PG_PASS=... and provide filename.tsv as an arg"
  echo "$0: PG_PASS=... ./geodata.sh filename.tsv"
  exit 1
fi
ruby geodata.rb $1
