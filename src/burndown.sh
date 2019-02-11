#!/bin/bash
function cleanup {
  git checkout master src/cncf-config/email-map src/github_users.json
  rm -f cncf-config/email-map github_users.json
}

trap cleanup EXIT

function analysis {
  echo "Analysing files $1 $2"
}

commits=`git log --format=format:%H`
for commit in $commits
do
  em='src/cncf-config/email-map'
  gu='src/github_users.json'
  git checkout $commit $em $gu 1>/dev/null 2>/dev/null
  res=$?
  if [ ! "$res" = "0" ]
  then
    em='cncf-config/email-map'
    gu='github_users.json'
    git checkout $commit $em $gu 1>/dev/null 2>/dev/null
    res=$?
    if [ "$res" = "0" ]
    then
      analysis $em $gu
    fi
  else
    analysis $em $gu
  fi
done
