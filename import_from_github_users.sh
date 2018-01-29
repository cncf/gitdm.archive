#!/bin/sh
ruby import_from_github_users.rb 'github_users.json'
cat new-email-map >> cncf-config/email-map
./sort_configs.sh
rm new-email-map
