#!/bin/bash
# manual mappings are in manual.json
echo "sort configs"
./sort_configs.sh
echo "company names mapping (currently manual)"
#./company_names_mapping.sh
# [MANUAL=1] [FULL=1] [NO_ACQS=1] ./company_names_mapping2.sh
./company_names_mapping2.sh
echo "lower unique"
./lower_unique.sh cncf-config/email-map
echo "json fields"
./check_json_fields.sh github_users.json
echo "forbidden data"
./handle_forbidden_data.sh
echo "consider ./check_spell, ./merge_mappings.sh, ./map_orgs.sh"
