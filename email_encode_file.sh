#!/bin/sh
echo "$1"
./encode_emails.rb "$1" tmp
mv tmp "$1"
