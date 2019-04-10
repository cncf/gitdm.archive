#!/bin/sh
WD=`pwd`
FN=$WD/k8s.log
> $FN
git config merge.renameLimit 100000
git config diff.renameLimit 100000
cd ~/dev/kubernetes_repos/kubernetes/
echo "Fetching kubernetes/kubernetes log"
git log --all --numstat -M >> $FN
git config --unset diff.renameLimit
git config --unset merge.renameLimit
PWD=$WD
cd $PWD
./commits_in_default_ranges.sh kubernetes $FN
rm -f $FN
