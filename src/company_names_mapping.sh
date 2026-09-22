#!/bin/bash
./sort_configs.sh
ruby ./company_names_mapping.rb merged-company-names-mapping cncf-config/email-map all_affs.csv github_users.json
#ruby ./company_names_mapping.rb company-names-mapping cncf-config/email-map all_affs.csv github_users.json
#echo "Consider 'ruby ./company_names_mapping.rb da-company-names-mapping.txt cncf-config/email-map all_affs.csv github_users.json'"
#ruby ./company_names_mapping.rb da-company-names-mapping.txt cncf-config/email-map all_affs.csv github_users.json
