#!/bin/sh
ruby lookup_json.rb github_users.json blog '/[^\\s]+/' affiliation '/^\(Unknown\)$/'
