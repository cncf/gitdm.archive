#!/bin/sh
# All unknown affiliations:
ruby lookup_json.rb github_users.json affiliation '/^\(Unknown\)$/' all_unknown.json
# Devs with Unknown affiliation having case insensitive "linkedin" in their blog or bio or location:
ruby lookup_json.rb github_users.json ':any?, blog, location, bio' '/linkedin/i' affiliation '/^\(Unknown\)$/' unknown_with_linkedin.json
# Devs with Unknown affiliation having blog property non-empty
ruby lookup_json.rb github_users.json blog '/[^\s]+/' affiliation '/^\(Unknown\)$/' unknown_with_blog.json
# Devs with Unknown affiliation having location & name property non-empty
ruby lookup_json.rb github_users.json 'location,name' '/[^\s]+/' affiliation '/^\(Unknown\)$/' unknown_with_location_and_name.json
