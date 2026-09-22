#!/bin/sh
cp github_users.json github_users.old
ruby ghusers.rb
./encode_emails.rb github_users.json temp
mv temp github_users.json
