#!/bin/sh
PWD=`pwd`
FNP=$PWD/first_run_patch
FNN=$PWD/first_run_numstat
cd ~/dev/go/src/k8s.io/kubernetes/
git config merge.renameLimit 100000
git config diff.renameLimit 100000
# git log --all -p -M | cncfdm.py -r '^vendor/|/vendor/|^Godeps/' -R -b ~/dev/gitdm/ > first_run.txt
# -m --> map unknowns to 'DomainName *' , -u map unknowns to '(Unknown)'
git log --all -p -M | ~/dev/cncf/gitdm/cncfdm.py -r '^vendor/|/vendor/|^Godeps/' -R -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -h $FNP.html -o $FNP.txt -x $FNP.csv
git log --all --numstat -M | ~/dev/cncf/gitdm/cncfdm.py -r '^vendor/|/vendor/|^Godeps/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -h $FNN.html -o $FNN.txt -x $FNN.csv > $FNN.out
git config --unset diff.renameLimit
git config --unset merge.renameLimit
cd $PWD

