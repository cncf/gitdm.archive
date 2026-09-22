#!/bin/sh
echo "$1"
./decode_emails.rb "$1" tmp
mv tmp "$1"
