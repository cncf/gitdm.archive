#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: you need to set password via PG_PASS=... and provide file.json file2.json as args"
  echo "$0: PG_PASS=... ./geousers.sh github_users.json stripped.json"
  exit 1
fi
ruby geousers.rb $1 $2
