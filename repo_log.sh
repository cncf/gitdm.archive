#!/bin/bash
if [ -z "${1}" ]
then
  echo "$0: argument required"
  exit 1
fi
WD=`pwd`
FN="$WD/git_logs/${1//\//_}.log"
cd "$1" || exit 2
git config merge.renameLimit 100000 || exit 3
git config diff.renameLimit 100000 || exit 4
git fetch origin || exit 4
git reset --hard origin/master || exit 5
git pull || exit 6
git log --numstat -M > $FN || exit 7
git config --unset diff.renameLimit || exit 8
git config --unset merge.renameLimit || exit 9
ls -l $FN
