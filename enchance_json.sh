#!/bin/sh
# actors.txt is a list of all distinct GitHub logins, comes from: generate_actors.sh
# vim actors.txt to remove formatting etc.
ruby enchance_json.rb github_users.json all_affs.csv actors.txt cncf-config/email-map
echo 'This is *NOT* using affiliations guess by name, to change this update to "guess_by_name = true" in enchance_json.rb'
