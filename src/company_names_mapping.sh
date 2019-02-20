#!/bin/bash
./sort_configs.sh
ruby ./company_names_mapping.rb company-names-mapping cncf-config/email-map all_affs.csv github_users.json
