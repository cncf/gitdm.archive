#!/bin/sh
#ruby import_from_json.rb cncf-config/domain-map stats/all_devs_gitdm.csv ~/dev/stackalytics/etc/default_data.json new-domain-map new-email-map
# all_affs.csv comes from manual_run.sh
ruby import_from_json.rb cncf-config/domain-map all_affs.csv ~/dev/stackalytics/etc/default_data.json new-domain-map new-email-map
