#!/bin/bash
# NOPULL=1 skip pulling existing repos
# NOCLONE=1 skip cloning repos
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
    if [ -z "$NOPULL" ]
    then
      echo "reset $o/$r"
      git reset --hard || echo "failed pull $o/$r"
      echo "pull $o/$r"
      git pull || echo "failed pull $o/$r"
    fi
  else
    if [ -z "$NOCLONE" ]
    then
      echo "clone $o/$r"
      git clone "https://github.com/$o/${r}.git"
  fi
  fi
done
echo 'OK'
