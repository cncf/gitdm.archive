#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide JSON filename as an argument"
  exit 1
fi
#ruby delete_json_fields.rb "$1" 'avatar_url,gravatar_id,url,html_url,followers_url,following_url,gists_url,starred_url,subscriptions_url,organizations_url,repos_url,events_url,received_events_url,emails,twitter_username,sex,sex_prob,age,tz'
ruby delete_json_fields.rb "$1" 'avatar_url,gravatar_id,url,html_url,followers,following,followers_url,following_url,gists_url,starred_url,subscriptions_url,organizations_url,repos_url,events_url,received_events_url,emails,twitter_username,sex,sex_prob,age,tz,type,site_admin,hireable,created_at,update_at,updated_at,public_repos,public_gists'
