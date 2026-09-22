#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] )
then
  echo "$0: you need to set password via PG_PASS=... and provide file.json file2.json file3.json as args"
  echo "$0: PG_PASS=... ./geousers.sh github_users.json stripped.json geousers_cache.json"
  exit 1
fi
backup=$4
if [ -z "$4" ]
then
  backup=2000
fi

ruby geousers.rb $1 $2 $3 $backup
./sort_json.rb $1
