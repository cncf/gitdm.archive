#!/bin/bash
if [ -z "${1}" ]
then
  echo "$0: argument required"
  exit 1
fi
WD=`pwd`
FNR="${WD}/git_logs/${1//\//_}"
LFN="${FNR}.log"
FN1="${FNR}.1"
FN2="${FNR}.2"
cd "$1" 1>"$FN1" 2>"$FN2" || exit 2
git fetch origin 1>>"$FN1" 2>>"$FN2"
git reset --hard origin/master 1>>"$FN1" 2>>"$FN2"
git pull 1>>"$FN1" 2>>"$FN2"
git log --all --numstat -M 2>>"$FN2" 1> $LFN
