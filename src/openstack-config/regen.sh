#!/bin/bash

echo "Refreshing git repos"
HERE=`pwd`
cd ~/git/openstack
for i in *; do
  cd $i && git pull && cd ..
done
cd $HERE

echo "Collecting revisions..."

grep -v '^#' havana-all | \
      while read project revisions; do \
        cd ~/git/openstack/$project; \
        git log --all | awk -F '[<>]' '/^Author:/ {print $2}'; \
      done | sort | uniq | grep -v '\((none)\|\.local\)$' > tmp

echo "Building email list..."

sed 's/ /\n/' < aliases >> tmp
sed 's/ /\n/' < other-aliases >> tmp
(sort | uniq | grep -v '\((none)\|\.local\)$') < tmp > emails.txt

echo "Mapping to launchpad ids"

../tools/with_venv.sh python ../launchpad/map-email-to-lp-name.py \
  $(cat emails.txt) | sort > launchpad-ids.txt
