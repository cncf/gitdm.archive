#!/bin/bash
all=`cat $1`
for f in $all
do
  cd ~/devstats_repos/
  f=${f/,/}
  IFS='/'
  arr=($f)
  unset IFS
  o=${arr[0]}
  r=${arr[1]}
  if [ ! -d "$o" ]
  then
    echo "missing org $o"
    mkdir "$o" || exit 1
  fi
  cd "$o" || exit 2
  if [ -d "$r" ]
  then
    cd "$r" || exit 3
    echo "pull $o/$r" || echo "failed pull $o/$r"
    git pull
  else
    echo "clone $o/$r"
    git clone "https://github.com/$o/${r}.git" || exit 4
  fi
done
echo 'OK'
