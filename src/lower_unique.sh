#!/bin/bash
if [ "${1}" = "" ]
then
  echo "$0: need filename argument"
  exit 1
fi
grep -HIn '\w@\w' "${1}"
cp "${1}" out && vim -c "%s/[A-Z]/\L&/g|%s/\([a-zA-Z0-9]\)@\([a-zA-Z0-9]\)/\1!\2/g|w|q" out && cat out | sort > out1 && cat out | sort | uniq > out2 && diff out1 out2 && rm -f out out1 out2
