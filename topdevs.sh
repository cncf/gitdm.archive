#!/bin/sh
echo "Stats all repos"
ruby topdevs.rb repos/combined.csv
mv added.csv stats/all_added.csv
mv removed.csv stats/all_removed.csv
mv changesets.csv stats/all_changesets.csv
echo "Stats kubernetes/kubernetes all time"
ruby topdevs.rb kubernetes/all_time/first_run_patch.csv
mv added.csv stats/kubernetes_added.csv
mv removed.csv stats/kubernetes_removed.csv
mv changesets.csv stats/kubernetes_changesets.csv
echo "Stats kubernetes/kubernetes v1.6.0"
ruby topdevs.rb kubernetes/v1.5.0-v1.6.0/output_strict_patch.csv
mv added.csv stats/v1.6_added.csv
mv removed.csv stats/v1.6_removed.csv
mv changesets.csv stats/v1.6_changesets.csv
echo "Stats kubernetes/kubernetes v1.7.0"
ruby topdevs.rb kubernetes/v1.6.0-v1.7.0/output_strict_patch.csv
mv added.csv stats/v1.7_added.csv
mv removed.csv stats/v1.7_removed.csv
mv changesets.csv stats/v1.7_changesets.csv
