#!/bin/sh
WD=`pwd`
FN=$WD/git.log
F=$WD/repos/combined
F2=$WD/repos/combined_no_map
F3=$WD/repos/combined_with_map
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
cat git.log | ~/dev/cncf/gitdm/cncfdm.py -r '\/vendor\/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -h $F.html -o $F.txt -x $F.csv > $F.out
cat git.log | ~/dev/cncf/gitdm/cncfdm.py -r '\/vendor\/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -h $F2.html -o $F2.txt -x $F2.csv > $F2.out
cat git.log | ~/dev/cncf/gitdm/cncfdm.py -r '\/vendor\/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -m -h $F3.html -o $F3.txt -x $F3.csv > $F3.out
rm $FN
