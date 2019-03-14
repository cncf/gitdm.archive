#!/bin/sh
unset LC_ALL
unset LANG
cd ./cncf-config || exit 1
cat email-map | sort | uniq > out; mv out email-map
cat domain-map | sort | uniq > out; mv out domain-map
cat aliases | sort | uniq > out; mv out aliases
cd ..
cat company-names-mapping | sort | uniq > out; mv out company-names-mapping
sed -i '1d' all_affs.csv
cat all_affs.csv | sort | uniq > out
echo '"email","name","company","date_to","source"' > all_affs.csv
cat out >> all_affs.csv
