#!/bin/sh
echo "args: date_from date_to path_to_prometheus_repos_directory"
WD=`pwd`
FN=$WD/prometheus.log
F=$WD/prometheus_repos/prometheus_combined
F2=$WD/prometheus_repos/combined_no_map
F3=$WD/prometheus_repos/combined_with_map
> $FN
for var in `ls "$3"`
do
  echo "Processing $var"
  cd "$3/$var"
  git config merge.renameLimit 100000
  git config diff.renameLimit 100000
  git log --all --numstat -M --since "$1" --until "$2" >> $FN
  git config --unset diff.renameLimit
  git config --unset merge.renameLimit
  ls -l $FN
done
PWD=$WD
cd $PWD
cat prometheus.log | ~/dev/cncf/gitdm/cncfdm.py -n -b ~/dev/cncf/gitdm/ -f "$1" -e "$2"  -t -z -d -D -U -u -h $F.html -o $F.txt -x $F.csv > $F.out
cat prometheus.log | ~/dev/cncf/gitdm/cncfdm.py -n -b ~/dev/cncf/gitdm/ -f "$1" -e "$2"  -t -z -d -D -U -h $F2.html -o $F2.txt -x $F2.csv > $F2.out
cat prometheus.log | ~/dev/cncf/gitdm/cncfdm.py -n -b ~/dev/cncf/gitdm/ -f "$1" -e "$2"  -t -z -d -D -U -m -h $F3.html -o $F3.txt -x $F3.csv > $F3.out
rm $FN
