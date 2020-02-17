#!/bin/bash
./company_names_mapping.sh
./lower_unique.sh cncf-config/email-map
./check_json_fields.sh github_users.json
./handle_forbidden_data.sh
