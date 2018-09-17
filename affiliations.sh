#!/bin/bash
ruby affiliations.rb affiliations.csv github_users.json 2> affiliations.txt
echo "Affiliations saved in affiliations.txt, you can add them to email-map via 'cat affiliations.txt >> cncf-config/email-map'"
