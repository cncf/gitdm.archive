#!/bin/sh
# All unknown affiliations:
rm -f all_unknown.json all_unknown.date
ruby lookup_json.rb github_users.json affiliation '/^\(Unknown\)$/' all_unknown.json
# Devs with Unknown affiliation having case insensitive "linkedin" in their blog or bio or location:
rm -f unknown_with_linkedin.json unknown_with_linkedin.date
ruby lookup_json.rb github_users.json ':any?, blog, location, bio' '/linkedin/i' affiliation '/^\(Unknown\)$/' unknown_with_linkedin.json
# Devs with Unknown affiliation having blog property non-empty
rm -f unknown_with_blog.json unknown_with_blog.dat
ruby lookup_json.rb github_users.json blog '/[^\s]+/' affiliation '/^\(Unknown\)$/' unknown_with_blog.json
# Devs with Unknown affiliation having location & name property non-empty
rm -f unknown_with_location_and_name.json unknown_with_location_and_name.dat
ruby lookup_json.rb github_users.json 'location,name' '/[^\s]+/' affiliation '/^\(Unknown\)$/' unknown_with_location_and_name.json
# 2 committers with Unknown affiliation having location & name property non-empty
rm -f unknown_with_location_and_name2.json unknown_with_location_and_name2.dat
ruby lookup_json.rb github_users.json 'location,name' '/[^\s]+/' 'commits.to_s' '/^2$/' affiliation '/^\(Unknown\)$/' unknown_with_location_and_name2.json
# Unknown 2 committers
rm -f unknown_2_committers.json unknown_2_committers.dat
ruby lookup_json.rb github_users.json 'commits.to_s' '/^2$/' affiliation '/^\(Unknown\)$/' unknown_2_committers.json
# Unknown with any facebook, twitter links in any field
rm -f unknown_with_social.json unknown_with_social.dat
ruby lookup_json.rb github_users.json '*' '/facebook|twitter|linkedin/i' affiliation '/^\(Unknown\)$/' unknown_with_social.json
# Unknown with any facebook, twitter links in any field
rm -f unknown_with_at.json unknown_wit_at.dat
ruby lookup_json.rb github_users.json ':any?,name,company,blog,bio' '/@/' affiliation '/^\(Unknown\)$/' unknown_with_at.json
