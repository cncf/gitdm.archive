#!/bin/sh
PWD=`pwd`
FN=$PWD/other_repos/$2_$3_$4
cd "$1"
echo "Processing repo $1 $2 $3 $4"
git config merge.renameLimit 100000
git config diff.renameLimit 100000
git log --all --numstat -M --since "$3" --until "$4" | ~/dev/alt/gitdm/src/cncfdm.py -n -b ~/dev/alt/gitdm/src/ -t -z -d -D -U -u -f "$3" -e "$4" -h $FN.html -o $FN.txt -x $FN.csv > $FN.out
git config --unset diff.renameLimit
git config --unset merge.renameLimit
