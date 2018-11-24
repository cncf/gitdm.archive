#!/bin/sh
rm -f git_logs/*.log git_logs/*.1 git_logs/*.2
./all_repos_log.rb $*
