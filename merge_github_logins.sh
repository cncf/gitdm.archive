#!/bin/sh
ruby merge_github_logins.rb 'github_users.json' >> cncf-config/email-map
./sort_configs.sh
