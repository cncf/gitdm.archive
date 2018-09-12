#!/bin/bash
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: you need to provide file.json file2.json as args"
  echo "$0: API_KEY=... ./genderize.sh github_users.json stripped.json"
  exit 1
fi
ruby genderize.rb $1 $2
