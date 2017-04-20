#!/bin/sh
PWD=`pwd`
cd ~/dev/kubernetes/kubernetes/
git config merge.renameLimit 10000
git config diff.renameLimit 10000
# -m --> map unknowns to 'DomainName *' , -u map unknowns to '(Unknown)'
git log -p -M | /Users/mac/dev/cncf/gitdm/cncfdm.py -b /Users/mac/dev/cncf/gitdm/ -t -z -d -D -U -m -h run_with_map_patch.html -o run_with_map_patch.txt -x run_with_map_patch.csv
git log --numstat -M | /Users/mac/dev/cncf/gitdm/cncfdm.py -n -b /Users/mac/dev/cncf/gitdm/ -t -z -d -D -U -m -h run_with_map_numstat.html -o run_with_map_numstat.txt -x run_with_map_numstat.csv > run_with_map_numstat.out
git config --unset diff.renameLimit
git config --unset merge.renameLimit
cd $PWD

