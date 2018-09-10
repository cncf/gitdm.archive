#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$1" ] )
then
  echo "$0: you need to set password via PG_PASS=... and provide file.json as an arg"
  echo "$0: PG_PASS=... ruby geousers.rb github_users.json"
  exit 1
fi
ruby geousers.rb $1
