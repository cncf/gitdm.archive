#!/bin/sh
PREFIX=$1
FN=$2
DT_START=`ruby -e "require 'date'; puts Date.today - 366"`
DT_END=`ruby -e "require 'date'; puts Date.today - 1"`
echo "$FN analysis in $DT_START - $DT_END"
./commits_in_ranges.sh $PREFIX $FN "$DT_START" "$DT_END"
./commits_in_ranges.sh $PREFIX $FN "2016-05-01" "2016-06-01"
./commits_in_ranges.sh $PREFIX $FN "2016-06-01" "2016-07-01"
./commits_in_ranges.sh $PREFIX $FN "2016-07-01" "2016-08-01"
./commits_in_ranges.sh $PREFIX $FN "2016-08-01" "2016-09-01"
./commits_in_ranges.sh $PREFIX $FN "2016-09-01" "2016-10-01"
./commits_in_ranges.sh $PREFIX $FN "2016-10-01" "2016-11-01"
./commits_in_ranges.sh $PREFIX $FN "2016-11-01" "2016-12-01"
./commits_in_ranges.sh $PREFIX $FN "2016-12-01" "2017-01-01"
./commits_in_ranges.sh $PREFIX $FN "2017-01-01" "2017-02-01"
./commits_in_ranges.sh $PREFIX $FN "2017-02-01" "2017-03-01"
./commits_in_ranges.sh $PREFIX $FN "2017-03-01" "2017-04-01"
./commits_in_ranges.sh $PREFIX $FN "2017-04-01" "2017-05-01"
./commits_in_ranges.sh $PREFIX $FN "2017-05-01" "2017-06-01"
