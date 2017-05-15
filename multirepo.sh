#!/bin/sh
WD=`pwd`
FN=$WD/git.log
F=$WD/repos/combined
> $FN
for var in "$@"
do
  echo "Processing $var"
  cd "$var"
  git config merge.renameLimit 100000
  git config diff.renameLimit 100000
  git log --numstat -M >> $FN
  git config --unset diff.renameLimit
  git config --unset merge.renameLimit
  ls -l $FN
done
PWD=$WD
cd $PWD
cat git.log | ~/dev/cncf/gitdm/cncfdm.py -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -h $F.html -o $F.txt -x $F.csv > $F.out
rm $FN 
