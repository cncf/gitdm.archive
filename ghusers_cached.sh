#!/bin/sh
ruby ghusers.rb
./encode_emails.rb github_users.json temp
mv temp github_users.json
