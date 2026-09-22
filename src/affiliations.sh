#!/bin/bash
ruby affiliations.rb affiliations.csv github_users.json cncf-config/email-map
./sort_configs.sh
