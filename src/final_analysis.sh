#!/bin/sh
echo "Sort config files"
./sort_configs.sh

echo "Generate all.txt file and all_affs.csv"
./manual_all.sh

echo "Generate affiliations files"
./gen_aff_files.sh

echo "Correlations"
./correlations.sh

echo "Enchance JSON"
./enchance_json.sh

echo "Aliaser"
./aliaser.sh

echo "Lookup JSON"
./lookup_json.sh

echo 'Progress Report'
./progress_report.sh

echo 'Per files analysis'
./per_dirs.sh

echo 'Stacked charts'
./stacked_charts.sh

echo 'Done'

echo "vim all.txt all_affs.csv correlations.txt github_users.json aliaser.txt progress_report.txt ../developers_affiliations.txt ../company_developers.txt per_dirs/all_stats.csv"
