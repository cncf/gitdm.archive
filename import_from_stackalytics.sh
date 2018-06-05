#!/bin/bash
rm default_data.json || exit 1
wget https://raw.githubusercontent.com/openstack/stackalytics/master/etc/default_data.json || exit 2
./import_from_stackalytics.rb > out || exit 3
cat out | sort | uniq > cncf-config/email-map || exit 4
echo 'OK'
