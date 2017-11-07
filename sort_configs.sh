#!/bin/sh
unset LC_ALL
unset LANG
cd ./cncf-config || exit 1
cat email-map | sort > out; mv out email-map
cat domain-map | sort > out; mv out domain-map
cat aliases | sort > out; mv out aliases
