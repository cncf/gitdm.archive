#!/bin/sh
echo "Params: path_to_repo repo_name date_from date_to exclude_regexp"
PWD=`pwd`
FN1=$PWD/other_repos/$2_$3_$4_exclude
FN1=$PWD/other_repos/$2_$3_$4_include
cd "$1"
echo "Processing repo $1 $2 $3 $4"
git config merge.renameLimit 100000
git config diff.renameLimit 100000
echo "git log --numstat -M --since \"$3\" --until \"$4\" | ~/dev/cncf/gitdm/cncfdm.py -r \"$5\" -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -f \"$3\" -e \"$4\" -h $FN1.html -o $FN1.txt -x $FN1.csv > $FN1.out"
git log --numstat -M --since "$3" --until "$4" | ~/dev/cncf/gitdm/cncfdm.py -r $5 -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -f "$3" -e "$4" -h $FN1.html -o $FN1.txt -x $FN1.csv > $FN1.out
echo "git log --numstat -M --since \"$3\" --until \"$4\" | ~/dev/cncf/gitdm/cncfdm.py -r \"$5\" -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -f \"$3\" -e \"$4\" -h $FN2.html -o $FN2.txt -x $FN2.csv > $FN2.out"
git log --numstat -M --since "$3" --until "$4" | ~/dev/cncf/gitdm/cncfdm.py -r $5 -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -f "$3" -e "$4" -h $FN2.html -o $FN2.txt -x $FN2.csv > $FN2.out
git config --unset diff.renameLimit
git config --unset merge.renameLimit
