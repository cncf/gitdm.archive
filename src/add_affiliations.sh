#!/bin/sh
~/dev/cncf/gitdm/cncfdm.py -i git.log -r "^vendor/|/vendor/|^Godeps/" -R -n -b ./ -t -z -d -D -U -u -o all.txt -x all.csv -a all_affs.csv > all.out
SKIP_COMPANIES="(Unknown)" ./gen_aff_files.sh
./enchance_json.sh
