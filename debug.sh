#!/bin/sh
PWD=`pwd`
cd ~/dev/kubernetes/kubernetes/
git config merge.renameLimit 10000
git config diff.renameLimit 10000
#git log -p -M | cncfdm.py -b /Users/mac/dev/gitdm/ -X -t -z -d -D -U -u -h first_run_patch.html -o first_run_patch.txt -x first_run_patch.csv
#git log -p -M > git-full.log
/Users/mac/dev/cncf/gitdm/cncfdm.py -i git-full.log -b /Users/mac/dev/cncf/gitdm/ -X -t -z -d -D -U -m -h first_run_patch.html -o first_run_patch.txt -x first_run_patch.csv
#cncfdm.py -i git-numstat.log -n -b /Users/mac/dev/gitdm/ -X -t -z -d -D -U -u -h first_run_patch.html -o first_run_patch.txt -x first_run_patch.csv
git config --unset diff.renameLimit
git config --unset merge.renameLimit
cp first_run.txt ~/dev/gitdm/
cd $PWD

