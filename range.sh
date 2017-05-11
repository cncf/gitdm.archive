#!/bin/sh
PWD=`pwd`
FN=$PWD/range
cd ~/dev/go/src/k8s.io/kubernetes/
git config merge.renameLimit 10000
git config diff.renameLimit 10000
git log -p -M | ~/dev/cncf/gitdm/cncfdm.py -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -f "$1" -e "$2" -h $FN.html -o $FN.txt -x $FN.csv
git config --unset diff.renameLimit
git config --unset merge.renameLimit
cd $PWD

