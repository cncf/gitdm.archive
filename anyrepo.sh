#!/bin/sh
PWD=`pwd`
FN=$PWD/repos/$2
cd "$1"
echo "Processing repo $1 $2"
git config merge.renameLimit 100000
git config diff.renameLimit 100000
git log --numstat -M | ~/dev/cncf/gitdm/cncfdm.py -r '\/vendor\/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -h $FN.html -o $FN.txt -x $FN.csv > $FN.out
git config --unset diff.renameLimit
git config --unset merge.renameLimit
