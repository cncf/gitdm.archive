#!/bin/sh
ruby merge_github_logins.rb 'github_users.json' >> cncf-config/email-map
./sort_configs.sh
ruby check_map_file.rb cncf-config/email-map > out
mv out cncf-config/email-map
