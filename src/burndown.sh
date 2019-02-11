#!/bin/bash
function cleanup {
  git checkout master src/cncf-config/email-map src/github_users.json
  rm -rf cncf-config github_users.json
}

trap cleanup EXIT

function analysis {
  unknowns=`grep -E '"affiliation": ("NotFound"|"\(Unknown\)"|""|"\?"|null)' "$3" | wc -l`
  affs=`grep -E '[^\s!]+![^\s!]+' "$2" | wc -l`
  echo "Analysing date $1, files $2 $3, unknowns: $unknowns, affiliations: $affs"
  echo "$1,$affs,$unknowns" >> src/burndown.csv
}

commits=`git log --format=format:'%H;%ci'`
last_date=''
for commit_data in $commits
do
  IFS=';'
  arr=($commit_data)
  unset IFS
  commit=${arr[0]}
  len=${#commit}
  if [ ! "$len" = "40" ]
  then
    continue
  fi
  date=${arr[1]}
  if [ "$date" = "$last_date" ]
  then
    continue
  fi
  last_date=$date
  # echo "Date: $date, commit: $commit"
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
      analysis $date $em $gu
    fi
  else
    analysis $date $em $gu
  fi
done

cat src/burndown.csv | sort > out
echo 'Date,Found,Unknowns' > src/burndown.csv
cat out >> src/burndown.csv
rm out

cleanup
