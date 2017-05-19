#!/bin/sh
echo "Stats all repos"
ruby topdevs.rb repos/combined.csv
mv added.csv stats/all_added.csv
mv removed.csv stats/all_removed.csv
mv changesets.csv stats/all_changesets.csv
echo "Stats kubernetes/kubernetes"
ruby topdevs.rb kubernetes/all_time/first_run_patch.csv
mv added.csv stats/kubernetes_added.csv
mv removed.csv stats/kubernetes_removed.csv
mv changesets.csv stats/kubernetes_changesets.csv
