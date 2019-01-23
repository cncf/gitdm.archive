#!/bin/sh
echo "Args git.log dt_from dt_to"
WD=`pwd`
PREFIX=$1
FN=$2
F=$WD/other_repos/$1_range_unknown_$3_$4
F2=$WD/other_repos/$1_range_no_map_$3_$4
F3=$WD/other_repos/$1_range_with_map_$3_$4
cat $FN | ~/dev/cncf/gitdm/cncfdm.py -f "$3" -e "$4" -r '^vendor/|/vendor/|^Godeps/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -u -h $F.html -o $F.txt -x $F.csv > $F.out
#cat $FN | ~/dev/cncf/gitdm/cncfdm.py -f "$3" -e "$4" -r '^vendor/|/vendor/|^Godeps/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -h $F2.html -o $F2.txt -x $F2.csv > $F2.out
#cat $FN | ~/dev/cncf/gitdm/cncfdm.py -f "$3" -e "$4" -r '^vendor/|/vendor/|^Godeps/' -R -n -b ~/dev/cncf/gitdm/ -t -z -d -D -U -m -h $F3.html -o $F3.txt -x $F3.csv > $F3.out
