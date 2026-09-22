#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide JSON filename as an argument"
  exit 1
fi
# fields='login,id,node_id,type,site_admin,name,company,blog,location,email,hireable,bio,public_repos,public_gists,followers,following,created_at,updated_at,commits,affiliation,country_id,tz,sex,sex_prob,source,age'
fields='login,id,node_id,type,site_admin,name,company,blog,location,email,hireable,bio,public_repos,public_gists,followers,following,created_at,updated_at,commits,affiliation,country_id,source'
if [ ! -z "$2" ]
then
  if [ "$2" = "small" ]
  then
    # fields='login,email,affiliation,source,name,commits,location,country_id,sex,sex_prob,tz,age'
    fields='login,email,affiliation,source,name,commits,location,country_id'
  else
    fields="$2"
  fi
fi
ruby check_json_fields.rb "$1" "$fields"
