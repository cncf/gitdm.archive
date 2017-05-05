#!/bin/sh
PWD=`pwd`
FN=$PWD/debug_run_patch
cd ~/dev/go/src/k8s.io/kubernetes/
git config merge.renameLimit 10000
git config diff.renameLimit 10000
#git log -p -M | cncfdm.py -b ~/dev/gitdm/ -X -t -z -d -D -U -u -h $FN.html -o $FN.txt -x $FN.csv
#git log -p -M > git-full.log
~/dev/cncf/gitdm/cncfdm.py -i git-full.log -b ~/dev/cncf/gitdm/ -X -t -z -d -D -U -m -h $FN.html -o $FN.txt -x $FN.csv
#cncfdm.py -i git-numstat.log -n -b ~/dev/gitdm/ -X -t -z -d -D -U -u -h $FN.html -o $FN.txt -x $FN.csv
git config --unset diff.renameLimit
git config --unset merge.renameLimit
cd $PWD

