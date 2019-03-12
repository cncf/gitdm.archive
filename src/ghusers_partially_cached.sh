#!/bin/sh
cp github_users.json github_users.old
# ruby ghusers.rb rc
# ruby ghusers.rb r
if [ -z "$1" ]
then
  ruby ghusers.rb rn
else
  ruby ghusers.rb "$1"
fi
#./encode_emails.rb github_users.json temp
#mv temp github_users.json
