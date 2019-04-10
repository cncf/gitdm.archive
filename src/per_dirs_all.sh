#!/bin/sh
PWD=`pwd`
FN=$PWD/per_dirs/all
LOG=$PWD/per_dirs/k8s_all.log
cd ~/dev/go/src/k8s.io/kubernetes/
git config merge.renameLimit 100000
git config diff.renameLimit 100000
echo 'Generating git log...'
git log --all --numstat -M > $LOG
ls -l $LOG
echo 'Analysing data...'
~/dev/cncf/gitdm/cncfdm.py -i $LOG -r '^vendor/|/vendor/|^Godeps/' -R -d -n -b ~/dev/cncf/gitdm/ -u -o $FN.txt -I $FN.csv > $FN.out
#~/dev/cncf/gitdm/cncfdm.py -i $LOG -r '^vendor/|/vendor/|^Godeps/' -R -d -n -b ~/dev/cncf/gitdm/ -u -o $FN.txt -I $FN.csv
git config --unset diff.renameLimit
git config --unset merge.renameLimit
cd $PWD
ls -l $FN.csv
echo 'Done.'
