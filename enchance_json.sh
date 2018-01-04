#!/bin/sh
# actors.txt is a list of all distinct GitHub logins, comes from: generate_actors.sh
# vim actors.txt to remove formatting etc.
ruby enchance_json.rb github_users.json all_affs.csv actors.txt
