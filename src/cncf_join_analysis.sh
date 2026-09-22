#!/bin/sh
echo "args: project_name join_date range_days path_to_repos_directory"
WD=`pwd`
PROJECT=$1
JOIN_DATE=`ruby -e "require 'date'; puts Date.parse('$2')"`
BEFORE_DATE=`ruby -e "require 'date'; puts Date.parse('$2') - $3"`
AFTER_DATE=`ruby -e "require 'date'; puts Date.parse('$2') + $3"`
REPOS_DIR=$4
FN_BEFORE=$WD/${PROJECT}_before.log
FN_AFTER=$WD/${PROJECT}_after.log
mkdir "$WD/${PROJECT}_repos" 2>/dev/null
BEFORE="$WD/${PROJECT}_repos/combined_before"
AFTER="$WD/${PROJECT}_repos/combined_after"
RESULT="$WD/${PROJECT}_repos/result.txt"
> $FN_BEFORE
> $FN_AFTER
for var in `ls "$REPOS_DIR"`
do
  echo "Processing $REPOS_DIR/$var"
  cd "$REPOS_DIR/$var"
  git config merge.renameLimit 100000
  git config diff.renameLimit 100000
  git log --all --numstat -M --since "$BEFORE_DATE" --until "$JOIN_DATE" >> $FN_BEFORE
  git log --all --numstat -M --since "$JOIN_DATE" --until "$AFTER_DATE" >> $FN_AFTER
  git config --unset diff.renameLimit
  git config --unset merge.renameLimit
  ls -l $FN_BEFORE $FN_AFTER
done
PWD=$WD
cd $PWD
cat $FN_BEFORE | ~/dev/cncf/gitdm/cncfdm.py -n -b ~/dev/cncf/gitdm/ -f "$BEFORE_DATE" -e "$JOIN_DATE" -t -z -d -D -U -o $BEFORE.txt -x $BEFORE.csv > $BEFORE.out
cat $FN_AFTER | ~/dev/cncf/gitdm/cncfdm.py -n -b ~/dev/cncf/gitdm/ -f "$JOIN_DATE" -e "$AFTER_DATE" -t -z -d -D -U -o $AFTER.txt -x $AFTER.csv > $AFTER.out
rm $FN_BEFORE $FN_AFTER
echo "$PROJECT before joining CNCF: From: $BEFORE_DATE to $JOIN_DATE:" > $RESULT
head -n 1 $BEFORE.txt >> $RESULT
head -n 3 $BEFORE.txt | tail -n 1 >> $RESULT
echo "CNCF Join date: $JOIN_DATE" >> $RESULT
echo "$PROJECT after joining CNCF: From: $JOIN_DATE to $AFTER_DATE:" >> $RESULT
head -n 1 $AFTER.txt >> $RESULT
head -n 3 $AFTER.txt | tail -n 1 >> $RESULT
echo "Results saved to $RESULT"
cat $RESULT
ruby percent_stats.rb $RESULT >> $RESULT
