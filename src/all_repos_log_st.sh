#!/bin/sh
WD=`pwd`
FN=$WD/git.log
> $FN
for var in "$@"
do
  echo "Processing $var"
  cd "$var"
  git config merge.renameLimit 100000
  git config diff.renameLimit 100000
  git log --all --numstat -M >> $FN
  git config --unset diff.renameLimit
  git config --unset merge.renameLimit
  ls -l $FN
done
