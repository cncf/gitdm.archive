#!/bin/sh
echo "Stats all repos"
ruby topdevs.rb repos/combined.csv
cp changesets.csv all_changesets.csv
cp changed.csv all_changed.csv
cp added.csv all_added.csv
cp removed.csv all_removed.csv
head -n 101 added.csv > stats/all_added.csv
head -n 101 removed.csv > stats/all_removed.csv
head -n 101 changesets.csv > stats/all_changesets.csv
head -n 101 changed.csv > stats/all_changed.csv
echo "Stats kubernetes/kubernetes all time"
ruby topdevs.rb kubernetes/all_time/first_run_patch.csv
head -n 101 added.csv > stats/kubernetes_added.csv
head -n 101 removed.csv > stats/kubernetes_removed.csv
head -n 101 changesets.csv > stats/kubernetes_changesets.csv
head -n 101 changed.csv > stats/kubernetes_changed.csv
echo "Stats kubernetes/kubernetes v1.6.0"
ruby topdevs.rb kubernetes/v1.5.0-v1.6.0/output_strict_patch.csv
head -n 101 added.csv > stats/v1.6_added.csv
head -n 101 removed.csv > stats/v1.6_removed.csv
head -n 101 changesets.csv > stats/v1.6_changesets.csv
head -n 101 changed.csv > stats/v1.6_changed.csv
echo "Stats kubernetes/kubernetes v1.7.0"
ruby topdevs.rb kubernetes/v1.6.0-v1.7.0/output_strict_patch.csv
head -n 101 added.csv > stats/v1.7_added.csv
head -n 101 removed.csv > stats/v1.7_removed.csv
head -n 101 changesets.csv > stats/v1.7_changesets.csv
head -n 101 changed.csv > stats/v1.7_changed.csv
rm -f added.csv removed.csv changesets.csv changed.csv
