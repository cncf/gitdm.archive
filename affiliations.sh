#!/bin/bash
ruby affiliations.rb affiliations.csv > affiliations.out
cat affiliations.out
echo "Affiliations saved in affiliations.out, you can add them to email-map via 'cat affiliations.out >> cncf-config/email-map'"
