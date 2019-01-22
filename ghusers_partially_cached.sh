#!/bin/sh
cp github_users.json github_users.old
# ruby ghusers.rb rc
ruby ghusers.rb rn
#./encode_emails.rb github_users.json temp
#mv temp github_users.json
