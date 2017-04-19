#!/bin/sh
PWD=`pwd`
cd ~/dev/kubernetes/kubernetes/
git config merge.renameLimit 10000
git config diff.renameLimit 10000
# git log -p -M | cncfdm.py -b /Users/mac/dev/gitdm/ > first_run.txt
# LG: one we have correct mapping, split this to make stats for revisions: v1.0-v1.1, v1.1-v1.2, ..., v1.5-v1.6 (kubernetes case) 
git log -p -M | cncfdm.py -b /Users/mac/dev/gitdm/ -t -z -d -D -U -u -h first_run_patch.html -o first_run_patch.txt -x first_run_patch.csv
git log --numstat -M | cncfdm.py -n -b /Users/mac/dev/gitdm/ -t -z -d -D -U -u -h first_run_numstat.html -o first_run_numstat.txt -x first_run_numstat.csv > first_run_numstat.out
git config --unset diff.renameLimit
git config --unset merge.renameLimit
cp first_run.txt ~/dev/gitdm/
cd $PWD

