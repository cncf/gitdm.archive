#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide JSON filename as an argument"
  exit 1
fi
ruby delete_json_fields.rb "$1" 'avatar_url,gravatar_id,url,html_url,followers_url,following_url,gists_url,starred_url,subscriptions_url,organizations_url,repos_url,events_url,received_events_url'
