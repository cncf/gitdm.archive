#!/bin/sh
# ~/dev/cncf/gitdm/cncfdm.py -i all.log -r '^vendor/|/vendor/|^Godeps/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -o all.txt -x all.csv
# ~/dev/cncf/gitdm/cncfdm.py -i trunc.log -r '^vendor/|/vendor/|^Godeps/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -o all.txt -x all.csv -a all_affs.csv
~/dev/cncf/gitdm/cncfdm.py -i git.log -r '^vendor/|/vendor/|^Godeps/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -o all.txt -x all.csv -a all_affs.csv > all.out
# To debug do not redirect stdout:
#~/dev/cncf/gitdm/cncfdm.py -i git.log -r '^vendor/|/vendor/|^Godeps/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -o all.txt -x all.csv -a all_affs.csv
