#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "$0: you need to specify PG_PASS=..."
  exit 1
fi
if [ -z "${BRANCH}" ]
then
  export BRANCH='HEAD^'
fi
git pull
git diff "${BRANCH}" ../*.txt > input.diff
vim input.diff
./update_from_pr_diff.rb ./input.diff github_users.json cncf-config/email-map || exit 2
git diff
if [ -z "$PARTIAL" ]
then
  FULL=1 ./post_manual_checks.sh && ./post_manual_updates.sh
  git diff
  git status
fi
