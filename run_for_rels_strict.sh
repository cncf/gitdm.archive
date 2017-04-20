#!/bin/sh
if [ $# -lt 2 ]; then
  echo "$0 tag1 tag2"
  echo "Use "git tag -l" to see available tags"
  exit 1
fi
PWD=`pwd`
cd ~/dev/kubernetes/kubernetes/
git config merge.renameLimit 10000
git config diff.renameLimit 10000
# -m --> map unknowns to 'DomainName *' , -u map unknowns to '(Unknown)'
git log -p -M $1..$2 | /Users/mac/dev/cncf/gitdm/cncfdm.py -b /Users/mac/dev/cncf/gitdm/ -t -z -d -D -U -u -h output_patch.html -o output_patch.txt -x output_patch.csv
git log --numstat -M $1..$2 | /Users/mac/dev/cncf/gitdm/cncfdm.py -n -b /Users/mac/dev/cncf/gitdm/ -t -z -d -D -U -u -h output_numstat.html -o output_numstat.txt -x output_numstat.csv > output_numstat.out
git config --unset diff.renameLimit
git config --unset merge.renameLimit
ls -l output_*
cd $PWD
