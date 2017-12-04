#!/bin/sh
# actors.txt is a list of all distinct GitHub logins, comes from:
# cncf/devstats: sudo -u postgres psql < util_sql/contributing_actors.sql > actors.txt
ruby enchance_json.rb github_users.json all_affs.csv actors.txt
