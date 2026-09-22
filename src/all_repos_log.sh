#!/bin/sh
echo 'Cleanup data'
rm -f git_logs/*.log git_logs/*.1 git_logs/*.2
echo 'Ensure repos'
./ensure_repos.sh repos.txt
echo 'Analyse logs'
./all_repos_log.rb $*
echo 'Done'
