#!/bin/bash
# rm default_data.json || exit 1
# wget https://raw.githubusercontent.com/openstack/stackalytics/master/etc/default_data.json || exit 2
./import_from_stackalytics.rb || exit 3
echo 'OK'
