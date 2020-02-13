#!/bin/bash
./delete_json_fields.sh github_users.json
./sort_json.rb github_users.json
./unique_json.rb github_users.json
./strip_json.sh github_users.json stripped.json
ONLY_AFF=1 ./strip_json.sh github_users.json affiliated.json
cp affiliated.json ~/dev/go/src/github.com/cncf/devstats/github_users.json
./gen_aff_files.sh
