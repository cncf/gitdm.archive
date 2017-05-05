#!/bin/sh
PWD=`pwd`
FNP=$PWD/first_run_patch
FNN=$PWD/first_run_numstat
cd ~/dev/go/src/k8s.io/kubernetes/
git config merge.renameLimit 10000
git config diff.renameLimit 10000
# git log -p -M | cncfdm.py -b ~/dev/gitdm/ > first_run.txt
# LG: one we have correct mapping, split this to make stats for revisions: v1.0-v1.1, v1.1-v1.2, ..., v1.5-v1.6 (kubernetes case) 
# -m --> map unknowns to 'DomainName *' , -u map unknowns to '(Unknown)'
git log -p -M | ~/dev/cncf/gitdm/cncfdm.py -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -h $FNP.html -o $FNP.txt -x $FNP.csv
git log --numstat -M | ~/dev/cncf/gitdm/cncfdm.py -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -h $FNN.html -o $FNN.txt -x $FNN.csv > $FNN.out
git config --unset diff.renameLimit
git config --unset merge.renameLimit
cd $PWD

