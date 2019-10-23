#!/bin/bash
if ( [ -z "$1" ] || [ -z "$2" ]  || [ -z "$3" ] )
then
  echo "$0: you need to provide file.json file2.json file3.json as args"
  echo "$0: API_KEY=... ./nationalize.sh github_users.json stripped.json nationalize_cache.json"
  exit 1
fi
backup=$4
if [ -z "$4" ]
then
  backup=2000
fi
ruby nationalize.rb $1 $2 $3 $backup
./sort_json.rb $1
