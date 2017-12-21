#!/bin/sh
# actors.txt is a list of all distinct GitHub logins, comes from:
# cncf/devstats: sudo -u postgres psql gha < util_sql/contributing_actors.sql > actors.txt
# cncf/devstats: sudo -u postgres psql prometheus < util_sql/contributing_actors.sql >> actors.txt
# vim actors.txt to remove formatting etc.
ruby enchance_json.rb github_users.json all_affs.csv actors.txt
