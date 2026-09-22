#!/bin/sh
PWD=`pwd`
FN=$PWD/repo_$2_$3
cd "$1"
git config merge.renameLimit 100000
git config diff.renameLimit 100000
git log --all --numstat -M --since "$2" --until "$3" | ~/dev/cncf/gitdm/cncfdm.py -r '^vendor/|/vendor/|^Godeps/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -f "$2" -e "$3" -h $FN.html -o $FN.txt -x $FN.csv > $FN.out
git config --unset diff.renameLimit
git config --unset merge.renameLimit
