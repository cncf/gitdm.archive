#!/bin/bash
./company_names_mapping.sh
./lower_unique.sh cncf-config/email-map
./check_json_fields.sh
./handle_forbidden_data.sh
