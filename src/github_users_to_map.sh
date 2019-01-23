#!/bin/bash
ruby github_users_to_map.rb github_users.json >> cncf-config/email-map
./sort_configs.sh
