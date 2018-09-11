#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide file.json as an arg"
  echo "$0: ./genderize.sh github_users.json"
  exit 1
fi
ruby genderize.rb $1
